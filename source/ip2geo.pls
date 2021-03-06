CREATE OR REPLACE package ip2geo is

/**
  Identify geographical location based on IP (IPv4 or IPv6)

  Pinpoint your users locations, customize their experiences, prevent fraud and ensure compliance

  The actuall geolocation data are provided using the [ipinfo.io](https://ipinfo.io) REST web service
  Results are stored in a local cache (table) and used for subsequent queries (10x - 100x faster)

  While you can evaluate this API without access token you should sign up [ipnfo.io](https://ipinfo.io/pricing) to obtain an access token.
  Their free plan includes up to 50k lookups per month

  ```
  sql> select ip2geo.get_country('8.8.8.8') from dual;                    -- using the limited annonymous access
  sql> select ip2geo.get_country('8.8.8.8', '<access token>') from dual;  -- using the ipinfo.io access token
  ```  

  By default the API is using HTTPS. The trusted root certificate for ipinfo.io has to be added to Oracle Wallet and configured in APEX / Instance / .
  Oracle Autonomous Database and apex.oracle.com provides this out of the box.
  
  Alternativelly non secure HTTP connection can be forced:
  ```
  sql> select ip2geo.get_country(p_ip => '8.8.8.8', p_use_https => 0) from dual;
  ```

  Author:     Jan Navratil

  License:    MIT

  Repository: [github.com/navratil/ip2geo](https://github.com/navratil/ip2geo)

**/

  type geolocation_t is record (
    ip           varchar2(40),   -- 8.8.8.8               IPv4 or IPv6
    country      varchar2(2),    -- US                    ISO 3166-1 alpha 2 characters
    region       varchar2(100),  -- California            (generally less accurate than country)
    city         varchar2(100),  -- Mountain View         (generally less accurate than region)
    timezone     varchar2(40),   -- America/Los_Angeles   https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
    latitude     number(8,5),    -- 37.4056
    longitude    number(8,5),    -- -122.0775
    organisation varchar2(100)   -- AS15169 Google LLC    Owner of the IP address
  );  
  /** Record holding the geographical info - used in the get_geo function **/

  function get_country(
    p_ip           in varchar2, 
    p_access_token in varchar2 default null,
    p_use_https    in number default null,
    p_use_cache    in number default null
  ) return varchar2;
  /** Return ISO country code [ISO 3166-1 alpha 2 characters](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) for given IP address **/

  function get_timezone(
    p_ip           in varchar2, 
    p_access_token in varchar2 default null,
    p_use_https    in number default null,
    p_use_cache    in number default null
  ) return varchar2;
  /** Returns [timezone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) for given IP address **/

  function get_geo(
    p_ip           in varchar2, 
    p_access_token in varchar2 default null,
    p_use_https    in number default null,
    p_use_cache    in number default null
  ) return geolocation_t;
  /** Returns full geolocation info for given IP address 
  
      You can either set parameters 
  
  **/

  procedure configure(
    p_access_token in varchar2 default null,
    p_use_https    in number default 1,
    p_use_cache    in number default 1
  );

  /**
  Set configuration parameters for a session duration (not persisted) instead of passing them with eacho API call
  
  #### p_access_token

  Unique access token ([ipinfo.io](https://ipinfo.io))

  #### p_use_https
  
  Must be enabled for Oracle Authonomous Database. 
  Optional for self managed database. Oracle Wallet must be configured for https://ipinfo.io/ then

  #### p_use_cache

  When enabled (default) first query for specific IP is passed to ipinfo.io and subsequent are resolved using locally stored data.
  When disabled all queries are passed to ipinfo.io
  Disabling the cache does NOT clear the local cache table - see **clear_cache()**
  **/

  procedure clear_cache(p_older_than in timestamp default null); 
  /** Removes geographcal data cached in a local table **/

end ip2geo;
/


