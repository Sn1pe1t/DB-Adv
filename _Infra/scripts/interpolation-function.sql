-- FUNCTION: public.Шаг_Интерполяции(numeric)

-- DROP FUNCTION IF EXISTS public."Шаг_Интерполяции"(numeric);

CREATE OR REPLACE FUNCTION public."Шаг_Интерполяции"(
	"Температура" numeric)
    RETURNS "Интерполяция"
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
	var_result "Интерполяция";
	var_value numeric := "Температура";
begin 

	select
		-- x0: если замер отрицательный (вернулся NULL) - берем саму температуру замера
		COALESCE((SELECT MAX(t."Температура") FROM "Виртуальные поправки" t WHERE t."Температура" <= var_value), var_value),
		-- y0: если замер отрицательный - берем поправку от 0 градусов (0.5)
		COALESCE((SELECT t."Поправка"         FROM "Виртуальные поправки" t WHERE t."Температура" <= var_value ORDER BY t."Температура" DESC LIMIT 1), 0.5),
 
		-- x1: если замер > 40 (вернулся NULL) - берем саму температуру замера
		COALESCE((SELECT MIN(t."Температура") FROM "Виртуальные поправки" t WHERE t."Температура" >= var_value), var_value),
		-- y1: если замер > 40 - берем поправку от максимальных 40 градусов (4.5)
		COALESCE((SELECT t."Поправка"         FROM "Виртуальные поправки" t WHERE t."Температура" >= var_value ORDER BY t."Температура" ASC LIMIT 1), 4.5)
	into var_result.x0, var_result.y0, var_result.x1, var_result.y1;
 
	return var_result;
	
end;
$BODY$;

ALTER FUNCTION public."Шаг_Интерполяции"(numeric)
    OWNER TO postgres;

