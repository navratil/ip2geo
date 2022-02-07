## Package ip2geo

Geo-location PL/SQL API to identify geographical location based on IP for Oracle database 

Pinpoint your users locations, customize their experiences, prevent fraud and ensure compliance

The actuall geolocation data are provided using the [ipinfo.io](https://ipinfo.io) REST web service

Subsequent queries for the same IP are benefiting from a local cache (table IP2GEOLOCATION) that provides 100x faster response time.

## Getting started

```sql
set serveroutput on

declare
  l_geo ip2geo.geolocation_t;
begin
  l_geo := ip2geo.get_geo(p_ip => '8.8.8.8');
  dbms_output.put_line(l_geo.country);
  dbms_output.put_line(l_geo.region);  
  dbms_output.put_line(l_geo.city);    
  dbms_output.put_line(l_geo.timezone);      
  dbms_output.put_line(l_geo.latitude);      
  dbms_output.put_line(l_geo.longitude);      
  dbms_output.put_line(l_geo.organisation);      
end;
```

```
PL/SQL procedure successfully completed.

US
California
Mountain View
America/Los_Angeles
37.4056
-122.0775
AS15169 Google LLC
```

While you can evaluate this API without access token you should sign up [ipnfo.io](https://ipinfo.io/pricing) to obtain an access token.
Their free plan includes up to 50k lookups per month

Get country code using limited annonymous access (no access token)
```sql
sql> select ip2geo.get_country('8.8.8.8') from dual;                    
US
```
Get country code using access token
```sql
sql> select ip2geo.get_country('8.8.8.8', '<access token>') from dual;
US
```  

By default the API is using HTTPS. The trusted root certificate for ipinfo.io has to be added to Oracle Wallet and configured in APEX / Instance / .
Oracle Autonomous Database and apex.oracle.com provides this out of the box.
  
Alternativelly non secure HTTP connection can be forced:
```sql
sql> select ip2geo.get_country(p_ip => '8.8.8.8', p_use_https => 0) from dual;
```

## API Reference 

See [IP2GEO API Reference](api-reference.md)

## Installation

### Prerequisites

- Oracle Database 18c and newer
- Oracle Application Express 18.0 and newer (ip2geo is using APEX_WEB_SERVICE API)

### Automatic installation ([Package Manager for Oracle database](https://orapm.com))

```sql
SQL> exec orapm.install('navratil/ip2geo');
```

### Manual installation (SQLcl or SQLPlus)

```sql
SQL> @install.sql
```

