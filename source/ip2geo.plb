CREATE OR REPLACE package body ip2geo as

  -------------------------------------------------------------------  
  -- CONFIGURATION
  -------------------------------------------------------------------  

  -- https://ipinfo.io/pricing  : FREE PLAN: 50k / month & both HTTPS & HTTP   ... 1k/day @ no auth 
  c_endpoint_uri     constant varchar2(100) := 'ipinfo.io/%s/json?token=%s';
  c_ipinfo_url_http  constant varchar2(100) := 'http://'||c_endpoint_uri;
  c_ipinfo_url_https constant varchar2(100) := 'https://'||c_endpoint_uri;
      
  g_access_token    varchar2(100);
  g_use_https       number         := 1;  -- HTTPS requires ipinfo.io root SSL cert in Oracle Wallet
  g_use_cache       number         := 1;
  
  -------------------------------------------------------------------  
  -- PRIVATE 
  -------------------------------------------------------------------  
    
  procedure add_to_cache(p_geo in geolocation_t) 
  is
    pragma autonomous_transaction;
  begin
    insert into ip2geolocation(
      ip, 
      country_code, 
      region, 
      city, 
      latitude, 
      longitude, 
      timezone, 
      organisation, 
      created
    )
    values(
      p_geo.ip, 
      p_geo.country, 
      p_geo.region, 
      p_geo.city, 
      p_geo.latitude, 
      p_geo.longitude, 
      p_geo.timezone, 
      p_geo.organisation, 
      systimestamp
    );
    commit;
  end;

  procedure lookup_ipinfo(
    p_ip           in varchar2, 
    p_access_token in varchar2,
    p_use_https    in number,
    p_geo          in out geolocation_t
  ) is
    l_response varchar2(4000);
    l_json     json_object_t;
    l_location apex_t_number;
    l_url      varchar2(200);
  begin
    -- construct URL
    if nvl(p_use_https, g_use_https) > 0 then
      -- https
      l_url := apex_string.format(c_ipinfo_url_https, trim(p_ip), nvl(p_access_token, g_access_token));
    else
      -- http
      l_url := apex_string.format(c_ipinfo_url_http, trim(p_ip), nvl(p_access_token, g_access_token));
    end if;
    -- call webservice
    l_response := apex_web_service.make_rest_request(l_url, 'GET');
    if apex_web_service.g_status_code = 200 then
      -- parse response
      /*  
        {
          "ip": "137.254.7.76",
          "hostname": "inet-137-254-7-76.oracle.com",
          "city": "Austin",
          "region": "Texas",
          "country": "US",
          "loc": "30.2672,-97.7431",
          "org": "AS792 Oracle Corporation",
          "postal": "78701",
          "timezone": "America/Chicago"
        }      
      */
      l_json := json_object_t(l_response);
      p_geo.ip           := l_json.get_string('ip');
      p_geo.country      := substr(l_json.get_string('country'),1,2);
      p_geo.region       := substr(l_json.get_string('region'),1,100);
      p_geo.city         := substr(l_json.get_string('city'),1,100);
      p_geo.organisation := substr(l_json.get_string('org'),1,100);
      p_geo.timezone     := substr(l_json.get_string('timezone'),1,40);
      begin
        l_location       := apex_string.split_numbers(l_json.get_string('loc'), ',');
        p_geo.latitude   := l_location(1);
        p_geo.longitude  := l_location(2);
      exception
        when others then 
          p_geo.latitude  := null;
          p_geo.longitude := null;
      end;
    else
      -- !! http error 
      if apex_web_service.g_status_code = 403 then
        raise_application_error(-20403, 'Invalid access token - HTTP '||to_char(apex_web_service.g_status_code));
      else  
        raise_application_error(-20500, 'Unexpected response from ipinfo.io - HTTP '||to_char(apex_web_service.g_status_code));
      end if;
    end if;
  end;


  -------------------------------------------------------------------  
  -- PUBLIC
  -------------------------------------------------------------------  

  function get_country(
    p_ip           in varchar2, 
    p_access_token in varchar2,
    p_use_https    in number,
    p_use_cache    in number
  ) return varchar2 is  
    l_geo geolocation_t;
  begin
    if nvl(p_use_cache, g_use_cache) = 1 then
      select country_code into l_geo.country
      from ip2geolocation
      where ip = trim(p_ip);
    else
      lookup_ipinfo(p_ip, p_access_token, p_use_https, l_geo);
    end if;
    return l_geo.country;
  exception
    when no_data_found then
      lookup_ipinfo(p_ip, p_access_token, p_use_https, l_geo);
      if l_geo.country is not null then 
        add_to_cache(l_geo); 
      end if;
      return l_geo.country;
    when others then raise;
  end;  

  function get_timezone(
    p_ip           in varchar2, 
    p_access_token in varchar2,
    p_use_https    in number,
    p_use_cache    in number
  ) return varchar2 is  
    l_geo geolocation_t;
  begin
    if nvl(p_use_cache, g_use_cache) = 1 then
      select timezone into l_geo.timezone
      from ip2geolocation
      where ip = trim(p_ip);
    else
      lookup_ipinfo(p_ip, p_access_token, p_use_https, l_geo);
    end if;
    return l_geo.timezone;
  exception
    when no_data_found then
      lookup_ipinfo(p_ip, p_access_token, p_use_https, l_geo);
      if l_geo.country is not null then 
        add_to_cache(l_geo); 
      end if;
      return l_geo.timezone;
    when others then raise;
  end;  

  function get_geo(
    p_ip           in varchar2, 
    p_access_token in varchar2,
    p_use_https    in number,
    p_use_cache    in number
  ) return geolocation_t is
    l_geo geolocation_t;
  begin
    if nvl(p_use_cache, g_use_cache) = 1 then
      select ip, country_code, region, city, latitude, longitude, timezone, organisation
        into l_geo.ip, l_geo.country, l_geo.region, l_geo.city, l_geo.latitude, l_geo.longitude, l_geo.timezone, l_geo.organisation
      from ip2geolocation
      where ip = trim(p_ip);
    else
      lookup_ipinfo(p_ip, p_access_token, p_use_https, l_geo);
    end if;
    return l_geo;
  exception
    when no_data_found then
      lookup_ipinfo(p_ip, p_access_token, p_use_https, l_geo);
      if l_geo.country is not null then 
        add_to_cache(l_geo); 
      end if;
      return l_geo;
    when others then raise;
  end;  

  procedure configure(
    p_access_token in varchar2,
    p_use_https    in number,
    p_use_cache    in number
  ) is
  begin
    if p_use_https is not null then 
      g_use_https := p_use_https;
    end if;  
    if p_use_cache is not null then 
      g_use_cache := p_use_cache;
    end if;  
    if p_access_token is not null then
      g_access_token := trim(p_access_token);
    end if;
  end;
  
  procedure clear_cache(p_older_than in timestamp) is
  begin
    if p_older_than is null then
      execute immediate 'truncate table ip2geolocation';
    else
      delete from ip2geolocation where created < p_older_than;
    end if;    
  end;    

end ip2geo;
/
