CREATE OR REPLACE FUNCTION fnc_random_string( aLength integer) RETURNS character varying AS
$BODY$
DECLARE
    chars text[] := '{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z}';
    res character varying  := '';
    i integer := 0;
BEGIN
    IF aLength < 0 THEN
        raise exception 'Given length cannot be less than 0';
    END IF;
    FOR i IN 1..aLength LOOP
            res := res || chars[1+random()*(array_length(chars, 1)-1)];
        END LOOP;
    RETURN res;
END;
$BODY$ language plpgsql;
ALTER FUNCTION fnc_random_string( integer ) OWNER TO viousr;
GRANT EXECUTE ON FUNCTION fnc_random_string( integer ) TO viousr;

--SELECT fnc_random_string(15)