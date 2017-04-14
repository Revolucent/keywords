\c postgres

DROP DATABASE IF EXISTS keywords;
CREATE DATABASE keywords;

\c keywords

CREATE EXTENSION citext;
CREATE EXTENSION hstore;

CREATE TYPE tag AS ENUM ('os', 'lang', 'data', 'ide', 'aws', 'web', 'mobile', 'vcs', 'desktop');

CREATE TABLE keyword
(
  keyword CITEXT NOT NULL PRIMARY KEY
, tags tag[] NOT NULL CHECK(ARRAY_LENGTH(tags, 1) > 0)
, min_version TEXT
, max_version TEXT
);

CREATE FUNCTION keyword(_keyword TEXT, _tag tag[], _min_version TEXT = NULL, _max_version TEXT = NULL)
RETURNS VOID
LANGUAGE PLPGSQL AS $$
BEGIN
  INSERT INTO keyword(keyword, tags, min_version, max_version) VALUES(_keyword, _tag, _min_version, _max_version);
END;
$$;

DO $$
BEGIN
  -- Operating Systems
  PERFORM keyword('macOS', '{os}', '10.0', '10.12');
  PERFORM keyword('Windows', '{os}', '3.1', '10');
  PERFORM keyword('Linux', '{os}');
  PERFORM keyword('Ubuntu', '{os}');
  PERFORM keyword('iOS', '{os,mobile}', '2.0', '10.0');
  PERFORM keyword('Android', '{os,mobile}', '4.0 KitKat', '7.0 Nougat');
  PERFORM keyword('Windows Phone', '{os,mobile}', '8', '10');

  -- Languages
  PERFORM keyword('Swift', '{lang}', '1.0', '3.0');
  PERFORM keyword('C#', '{lang}', '1.0', '6.0');
  PERFORM keyword('REBOL', '{lang}', '2.0', '3.0');
  PERFORM keyword('Haskell', '{lang}', '2010', '2014');
  PERFORM keyword('Rust', '{lang}', '0.9', '1.16.0');
  PERFORM keyword('Objective-C', '{lang}', '1.0', '2.0');
  PERFORM keyword('C', '{lang}');
  PERFORM keyword('J', '{lang}', '603', '805');
  PERFORM keyword('Java', '{lang}', '1.2', '8.0');
  PERFORM keyword('Ruby', '{lang}', '1.6', '2.4');
  PERFORM keyword('XML', '{lang}');
  PERFORM keyword('HTML', '{lang,web}', '3.2', '5.0');
  PERFORM keyword('XSLT', '{lang}', '2.0');
  PERFORM keyword('XPath', '{lang}');
  PERFORM keyword('JSON', '{lang,web}');
  PERFORM keyword('JavaScript', '{lang,web}', '3', '6');
  PERFORM keyword('CoffeeScript', '{lang,web}');
  PERFORM keyword('XAML', '{lang}');
  PERFORM keyword('VimScript', '{lang}');
  PERFORM keyword('PowerShell', '{lang}', '1.0', '5.1');
  PERFORM keyword('Lua', '{lang}');
  PERFORM keyword('Clojure', '{lang}');

  -- Data Technologies
  PERFORM keyword('PostgreSQL', '{data}', '8.4', '9.6');
  PERFORM keyword('Microsoft SQL Server', '{data}', '6', '12');
  PERFORM keyword('MySQL', '{data}', '4.0', '5.7');
  PERFORM keyword('SQLite', '{data}', '3.5.5', '3.18.0');
  PERFORM keyword('Core Data', '{data}');
  PERFORM keyword('SQL', '{data}');

  -- Web Technologies
  PERFORM keyword('Ruby on Rails', '{web}', '3.0', '5.0');
  PERFORM keyword('ASP.NET MVC', '{web}', '2.0', '5.0');
  PERFORM keyword('Heroku', '{web}');

  -- Frameworks
--  PERFORM keyword('.NET', '{frwk}', '1.0');
  PERFORM keyword('WPF', '{desktop}');
  PERFORM keyword('Cocoa', '{desktop}', '10.0', '10.12');
  PERFORM keyword('Cocoa Touch', '{mobile}', '2.0', '10.0');
  
  -- IDEs
  PERFORM keyword('Vim', '{ide}', '7.3', '8.0');
  PERFORM keyword('Visual Studio', '{ide}', '6.0', '2017');
  PERFORM keyword('Atom', '{ide}', '1.0', '1.16');
  PERFORM keyword('Xcode', '{ide}', '1.0', '8.0');
  PERFORM keyword('Android Studio', '{ide,mobile}', '0.8', '2.3');

  -- Version Control System
  PERFORM keyword('Git', '{vcs}');

  -- Amazon
  PERFORM keyword('EC2', '{aws}');
  PERFORM keyword('S3', '{aws}');
  PERFORM keyword('RDS', '{aws}');
  PERFORM keyword('DynamoDB', '{aws,data}');
  PERFORM keyword('Lambda', '{aws}');
  PERFORM keyword('Elastic Beanstalk', '{aws}');
  PERFORM keyword('IAM', '{aws}');
  PERFORM keyword('SNS', '{aws}');
  
END;

$$;

CREATE FUNCTION format_keyword(_keyword keyword)
RETURNS TEXT
STRICT IMMUTABLE
LANGUAGE PLPGSQL AS $$
DECLARE _version TEXT;
BEGIN
  IF (_keyword.min_version) IS NOT NULL AND (_keyword.max_version) IS NOT NULL THEN
    _version := FORMAT(' (%s - %s)', (_keyword.min_version), (_keyword.max_version));
  ELSE
    _version := COALESCE((_keyword.min_version), (_keyword.max_version));    
    IF _version IS NOT NULL THEN
      _version := FORMAT(' (%s)', _version);
    END IF;
  END IF;
  _version := COALESCE(_version, '');
  RETURN FORMAT('%s%s', (_keyword.keyword), _version);
END;
$$;

CREATE TABLE talent
(
  category CITEXT NOT NULL PRIMARY KEY
, talents CITEXT NOT NULL
);

DO $$
DECLARE _tags HSTORE DEFAULT 'Mobile => mobile, Web => web, Languages => lang, "Data Technologies" => data, "Amazon Web Services (AWS)" => aws, "IDEs & Editors" => ide, "Operating Systems" => os';
DECLARE _key TEXT;
DECLARE _talents TEXT;
BEGIN
  FOREACH _key IN ARRAY AKEYS(_tags)
  LOOP
    INSERT
      INTO  talent
        (   category
        ,   talents   )
    SELECT  _key
        ,   ARRAY_TO_STRING(ARRAY_AGG(talent), ' • ')
    FROM    (SELECT format_keyword(keyword.*) talent FROM keyword WHERE tags @> ARRAY[_tags -> _key]::tag[] ORDER BY keyword) k;
  END LOOP;
END;
$$;

SELECT * FROM talent;
