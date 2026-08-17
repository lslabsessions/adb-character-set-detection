/*  01-environment-and-version.sql
	Check the database version, database character sets, session length
	semantics, and the presence of the new UTL_I18N detection procedures.*/

prompt === DATABASE VERSION ===

select banner_full
from v$version
where banner_full like 'Oracle%Database%';


prompt
prompt === DATABASE CHARACTER SETS ===

select parameter,
       value
from nls_database_parameters
where parameter in (
    'NLS_CHARACTERSET',
    'NLS_NCHAR_CHARACTERSET'
)
order by parameter;


prompt
prompt === SESSION LENGTH SEMANTICS ===

select parameter,
       value
from nls_session_parameters
where parameter = 'NLS_LENGTH_SEMANTICS';


prompt
prompt === UTL_I18N DETECTION PROCEDURES ===

select procedure_name,
       overload
from all_procedures
where owner = 'SYS'
  and object_name = 'UTL_I18N'
  and procedure_name in (
      'DETECT_CHARSET',
      'DETECT_LANGUAGE',
      'DETECT_LANGUAGE_CHARSET'
  )
order by procedure_name,
         overload;
