DROP FUNCTION IF EXISTS asset_address_list_explicit (text, text);

CREATE FUNCTION asset_address_list_explicit (_asset_policy text, _asset_name text)
  RETURNS TABLE (
    address varchar,
    quantity numeric)
  LANGUAGE PLPGSQL
  AS $$
DECLARE
  _asset_policy_decoded bytea;
  _asset_name_decoded bytea;
BEGIN
  SELECT
    DECODE(_asset_policy::text, 'hex') INTO _asset_policy_decoded;
  SELECT
    DECODE(_asset_name::text, 'escape') INTO _asset_name_decoded;
  RETURN QUERY
  SELECT
    TXO.ADDRESS,
    SUM(MTX.QUANTITY)
  FROM
    MA_TX_OUT MTX
    INNER JOIN MULTI_ASSET MA ON MA.id = MTX.ident
    INNER JOIN TX_OUT TXO ON TXO.ID = MTX.TX_OUT_ID
    LEFT JOIN TX_IN ON TXO.TX_ID = TX_IN.TX_OUT_ID
      AND TXO.INDEX::smallint = TX_IN.TX_OUT_INDEX::smallint
  WHERE
    MA.policy = _asset_policy_decoded
    AND MA.name = _asset_name_decoded
    AND TX_IN.TX_IN_ID IS NULL
  GROUP BY
    TXO.ADDRESS;
END;
$$;

COMMENT ON FUNCTION asset_address_list_explicit IS 'Get the list of all addresses containing a specific asset'  To use, load this code into the cexplorer database. Then you can query "select asset_address_list_explicit ('policyID', 'AssetName') ;
