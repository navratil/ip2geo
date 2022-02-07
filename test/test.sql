set serveroutput on
set timing on

prompt Running unit test for navratil/ip2geo

declare
  c_ip        constant varchar2(40) := '8.8.8.8';
  c_expected  constant varchar2(2) := 'US';
  l_result    varchar2(100);
  l_number    number;
  l_geo       ip2geo.geolocation_t;
  l_errors    pls_integer := 0;
begin  
  -- set defaults
  ip2geo.configure(
    p_access_token => ' ',
    p_use_cache => 1, 
    p_use_https => 1
  );

  -- #1 - Clear cache
  ip2geo.clear_cache;
  select count(*) into l_number from ip2geolocation;
  if (l_number != 0) then
    l_errors := l_errors + 1;
    dbms_output.put_line('#1');
  end if;

  -- #2 - Lookup & populate cache
  if (ip2geo.get_country(c_ip) != c_expected) then
    l_errors := l_errors + 1;
    dbms_output.put_line('#2 ');
  end if;
  -- modify cache so we know when it's coming from cache VS lookup
  update ip2geolocation set country_code = lower(country_code) where ip = c_ip;

  -- #3 - Cache
  if (ip2geo.get_country(c_ip) != lower(c_expected)) then
    l_errors := l_errors + 1;
    dbms_output.put_line('#3');
  end if;

  -- #4 - Lookup - Bypass cache
  if (ip2geo.get_country(p_ip => c_ip, p_use_cache => 0) != c_expected) then
    l_errors := l_errors + 1;
    dbms_output.put_line('#4');
  end if;

  -- #5 - session config
  ip2geo.configure(p_use_cache => 0);
  if (ip2geo.get_country(p_ip => c_ip) != c_expected) then
    l_errors := l_errors + 1;
    dbms_output.put_line('#5');
  end if;

  -- #6 - API param has priority over session config
  ip2geo.configure(p_use_cache => 0);
  if (ip2geo.get_country(p_ip => c_ip, p_use_cache => 1) != lower(c_expected)) then
    l_errors := l_errors + 1;
    dbms_output.put_line('#6');
  end if;

  -- #7 - Invalid token
  ip2geo.configure(p_access_token => 'fake-token-123456');
  begin
    l_result :=  ip2geo.get_country(p_ip => c_ip, p_use_cache => 0);
    l_errors := l_errors + 1;
    dbms_output.put_line('#7A');
  exception
    when others then
      if sqlcode <> -20403 then 
        l_errors := l_errors + 1;
        dbms_output.put_line('#7B');
      end if;
  end;      

  dbms_output.put_line('Total errors: '||l_errors);

end;
/