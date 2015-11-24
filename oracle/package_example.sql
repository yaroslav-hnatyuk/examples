CREATE OR REPLACE
PACKAGE BODY PK_NRG_OBJECTS
AS
  strCurAccountId SEC_ACCOUNTS.USER_ID%TYPE;
  dtCurdate TIMESTAMP(6) WITH LOCAL TIME ZONE;

  --------------------------------------------
  ------------Energy Object Types-------------
  --------------------------------------------
  FUNCTION ObjectTypeValidation
  (
    p_nObjectTypeId           NRG_OBJECT_TYPES.OBJECT_TYPE_ID%TYPE,
    p_strCode                 NRG_OBJECT_TYPES.CODE%TYPE,
    p_strReference            NRG_OBJECT_TYPES.REFERENCE%TYPE,
    p_nIsDefault              NRG_OBJECT_TYPES.IS_DEFAULT%TYPE,
    p_strHeatingBaseTemp      NRG_OBJECT_TYPES.HEATING_BASE_TEMP_ID%TYPE,
    p_strCoolingBaseTemp      NRG_OBJECT_TYPES.COOLING_BASE_TEMP_ID%TYPE,
    p_strUdiTableId           NRG_OBJECT_TYPES.UDI_TABLE_ID%TYPE
  )
    RETURN T_MESSAGE_ARRAY
  AS
    nDummy NUMBER;
  BEGIN
    --checking mandatory values
    IF p_strCode IS NULL THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_CODE_CANNOT_BE_EMPTY');
    END IF;

    IF p_strReference IS NULL THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_REFERENCE_CANNOT_BE_EMPTY');
    END IF;

    IF p_strHeatingBaseTemp IS NULL AND p_strCoolingBaseTemp IS NULL THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_ONE_OF_BASE_TEMP_IS_REQUIRED');
    END IF;

    --checking uniqueness
    BEGIN
      SELECT
        1
      INTO
        nDummy
      FROM
        NRG_OBJECT_TYPES
      WHERE
        UPPER(CODE) = UPPER(p_strCode) AND
        OBJECT_TYPE_ID <> NVL(p_nObjectTypeId, -1);
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_CODE_MUST_BE_UNIQUE',
                                                            p_strCode);
    EXCEPTION
      WHEN TOO_MANY_ROWS THEN
        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_CODE_MUST_BE_UNIQUE',
                                                              p_strCode);
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;

    BEGIN
      SELECT
        1
      INTO
        nDummy
      FROM
        NRG_OBJECT_TYPES
      WHERE
        UPPER(REFERENCE) = UPPER(p_strReference) AND
        OBJECT_TYPE_ID <> NVL(p_nObjectTypeId, -1);
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_REFERENCE_MUST_BE_UNIQUE',
                                                            p_strReference);
    EXCEPTION
      WHEN TOO_MANY_ROWS THEN
        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_REFERENCE_MUST_BE_UNIQUE',
                                                              p_strReference);
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;

    IF p_nIsDefault IS NOT NULL AND
       p_nIsDefault NOT IN (0, 1) THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_IS_DEFAULT_NOT_IN_0_1');
    END IF;

    IF p_nObjectTypeId IS NOT NULL THEN
      SELECT
        COUNT(*)
      INTO
        nDummy
      FROM
        NRG_OBJECT_TYPES
      WHERE
        IS_DEFAULT = 1 AND
        NOT (OBJECT_TYPE_ID = p_nObjectTypeId);

      IF NVL(p_nIsDefault,0) = 0 AND nDummy = 0 THEN
          RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_TYPE_SHOULD_BE_ONE_DEFAULT_VALUE');
      END IF;
    END IF;

    IF p_strUdiTableId IS NOT NULL THEN
      SELECT
        COUNT(1)
      INTO
        nDummy
      FROM
        UDI_TABLES
      WHERE
        UDI_TABLE_ID = p_strUdiTableId;
      IF nDummy = 0 THEN
        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_UDI_TABLE_ID_DOESNOT_EXISTS');
      END IF;
    END IF;

    --check if base temp has the same uom
    SELECT
      COUNT(1)
    INTO
      nDummy
    FROM
      NRG_BASE_TEMPERATURES BH,
      NRG_BASE_TEMPERATURES BC
    WHERE
      BH.BASE_TEMP_ID = NVL(p_strHeatingBaseTemp, BH.BASE_TEMP_ID) AND
      BC.BASE_TEMP_ID = NVL(p_strCoolingBaseTemp, BC.BASE_TEMP_ID) AND
      BC.TEMP_UOM_ID = BH.TEMP_UOM_ID;

    IF nDummy = 0 THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_TYPE_DIFFERENT_UOMS_FOR_BASE_TEMP');
    END IF;

    RETURN PK_MCS_APP_MESSAGES.ReturnTrue;
  END ObjectTypeValidation;

  FUNCTION CanInsertObjectType
  (
    p_strCode                 NRG_OBJECT_TYPES.CODE%TYPE,
    p_strReference            NRG_OBJECT_TYPES.REFERENCE%TYPE,
    p_nIsDefault              NRG_OBJECT_TYPES.IS_DEFAULT%TYPE,
    p_strHeatingBaseTemp      NRG_OBJECT_TYPES.HEATING_BASE_TEMP_ID%TYPE,
    p_strCoolingBaseTemp      NRG_OBJECT_TYPES.COOLING_BASE_TEMP_ID%TYPE
  )
    RETURN T_MESSAGE_ARRAY
  AS
    arRet T_MESSAGE_ARRAY;
  BEGIN
    IF NOT (PK_NRG_GENERAL.IsAuthorized('modEnergyObjectTypes') = '1') THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_NO_RIGHT_MOD_ENERGY_OBJECT_TYPES');
    END IF;

    arRet := ObjectTypeValidation(p_nObjectTypeId => NULL,
                                  p_strCode       => p_strCode,
                                  p_strReference  => p_strReference,
                                  p_nIsDefault    => p_nIsDefault,
                                  p_strHeatingBaseTemp => p_strHeatingBaseTemp,
                                  p_strCoolingBaseTemp => p_strCoolingBaseTemp,
                                  p_strUdiTableId => NULL);

    RETURN arRet;
  END CanInsertObjectType;

  FUNCTION InsertObjectType
  (
    p_strCode                 NRG_OBJECT_TYPES.CODE%TYPE,
    p_strReference            NRG_OBJECT_TYPES.REFERENCE%TYPE,
    p_nIsDefault              NRG_OBJECT_TYPES.IS_DEFAULT%TYPE,
    p_strHeatingBaseTemp      NRG_OBJECT_TYPES.HEATING_BASE_TEMP_ID%TYPE,
    p_strCoolingBaseTemp      NRG_OBJECT_TYPES.COOLING_BASE_TEMP_ID%TYPE
  )
    RETURN NRG_OBJECT_TYPES.OBJECT_TYPE_ID%TYPE
  AS
    nObjectTypeId NRG_OBJECT_TYPES.OBJECT_TYPE_ID%TYPE;
  BEGIN
    SELECT
      NRG_OBJECT_TYPES_GEN.NEXTVAL
    INTO
      nObjectTypeId
    FROM
      DUAL;

    m_bAllowIUD := TRUE;

    IF p_nIsDefault = 1 THEN
      UPDATE
        NRG_OBJECT_TYPES
      SET
        IS_DEFAULT = 0
      WHERE
        IS_DEFAULT = 1;
    END IF;

    INSERT INTO
      NRG_OBJECT_TYPES
      (
        OBJECT_TYPE_ID,
        CODE,
        REFERENCE,
        IS_DEFAULT,
        HEATING_BASE_TEMP_ID,
        COOLING_BASE_TEMP_ID
      )
    VALUES
      (nObjectTypeId, --OBJECT_TYPE_ID
       p_strCode, --CODE
       p_strReference, --REFERENCE
       NVL(p_nIsDefault, 0), --IS_DEFAULT
       p_strHeatingBaseTemp,
       p_strCoolingBaseTemp
                           );

    m_bAllowIUD := FALSE;

    RETURN nObjectTypeId;
  END InsertObjectType;

  FUNCTION CanUpdateObjectType
  (
    p_nObjectTypeId           NRG_OBJECT_TYPES.OBJECT_TYPE_ID%TYPE,
    p_strCode                 NRG_OBJECT_TYPES.CODE%TYPE,
    p_strReference            NRG_OBJECT_TYPES.REFERENCE%TYPE,
    p_nIsDefault              NRG_OBJECT_TYPES.IS_DEFAULT%TYPE,
    p_strHeatingBaseTemp      NRG_OBJECT_TYPES.HEATING_BASE_TEMP_ID%TYPE,
    p_strCoolingBaseTemp      NRG_OBJECT_TYPES.COOLING_BASE_TEMP_ID%TYPE,
    p_strUdiTableId           NRG_OBJECT_TYPES.UDI_TABLE_ID%TYPE
  )
    RETURN T_MESSAGE_ARRAY
  AS
    arRet T_MESSAGE_ARRAY;
    recOldVal NRG_OBJECT_TYPES%ROWTYPE;
  BEGIN
    IF NOT (PK_NRG_GENERAL.IsAuthorized('modEnergyObjectTypes') = '1') THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_NO_RIGHT_MOD_ENERGY_OBJECT_TYPES');
    END IF;

    IF p_nObjectTypeId IS NULL THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_WAS_NOT_SELECTED');
    END IF;

    BEGIN
      SELECT
        *
      INTO
        recOldVal
      FROM
        NRG_OBJECT_TYPES
      WHERE
        OBJECT_TYPE_ID = p_nObjectTypeId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_DOES_NOT_EXIST');
    END;

    /*IF recOldVal.IS_DEFAULT = 1 AND
       p_nIsDefault = 0 THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_ONLY_ONE_DEF_VALUE_MUST_EXIST');
    END IF;*/

    arRet := ObjectTypeValidation(p_nObjectTypeId => p_nObjectTypeId,
                                  p_strCode       => p_strCode,
                                  p_strReference  => p_strReference,
                                  p_nIsDefault    => p_nIsDefault,
                                  p_strHeatingBaseTemp => p_strHeatingBaseTemp,
                                  p_strCoolingBaseTemp => p_strCoolingBaseTemp,
                                  p_strUdiTableId => p_strUdiTableId);

    RETURN arRet;
  END CanUpdateObjectType;

  PROCEDURE UpdateObjectType
  (
    p_nObjectTypeId           NRG_OBJECT_TYPES.OBJECT_TYPE_ID%TYPE,
    p_strCode                 NRG_OBJECT_TYPES.CODE%TYPE,
    p_strReference            NRG_OBJECT_TYPES.REFERENCE%TYPE,
    p_nIsDefault              NRG_OBJECT_TYPES.IS_DEFAULT%TYPE,
    p_strHeatingBaseTemp      NRG_OBJECT_TYPES.HEATING_BASE_TEMP_ID%TYPE,
    p_strCoolingBaseTemp      NRG_OBJECT_TYPES.COOLING_BASE_TEMP_ID%TYPE,
    p_strUdiTableId           NRG_OBJECT_TYPES.UDI_TABLE_ID%TYPE
  )
  AS
  BEGIN
    m_bAllowIUD := TRUE;

    IF p_nIsDefault = 1 THEN
      UPDATE
        NRG_OBJECT_TYPES
      SET
        IS_DEFAULT = 0
      WHERE
        IS_DEFAULT = 1;
    END IF;

    UPDATE
      NRG_OBJECT_TYPES
    SET
      CODE = p_strCode,
      REFERENCE = p_strReference,
      IS_DEFAULT = NVL(p_nIsDefault, 0),
      HEATING_BASE_TEMP_ID = p_strHeatingBaseTemp,
      COOLING_BASE_TEMP_ID = p_strCoolingBaseTemp,
      UDI_TABLE_ID = p_strUdiTableId
    WHERE
      OBJECT_TYPE_ID = p_nObjectTypeId;

    m_bAllowIUD := FALSE;
  END UpdateObjectType;

  FUNCTION SaveObjectType
  (
    p_nObjectTypeId                        NRG_OBJECT_TYPES.OBJECT_TYPE_ID%TYPE,
    p_strCode                              NRG_OBJECT_TYPES.CODE%TYPE,
    p_strReference                         NRG_OBJECT_TYPES.REFERENCE%TYPE,
    p_nIsDefault                           NRG_OBJECT_TYPES.IS_DEFAULT%TYPE,
    p_strHeatingBaseTemp                   NRG_OBJECT_TYPES.HEATING_BASE_TEMP_ID%TYPE,
    p_strCoolingBaseTemp                   NRG_OBJECT_TYPES.COOLING_BASE_TEMP_ID%TYPE,
    p_strUdiTableId                        NRG_OBJECT_TYPES.UDI_TABLE_ID%TYPE,
    p_recErrors                            OUT NOCOPY T_MESSAGE_ARRAY
  )
    RETURN NRG_OBJECT_TYPES.OBJECT_TYPE_ID%TYPE
  AS
    arCheck T_MESSAGE_ARRAY;
    nObjectTypeId NRG_OBJECT_TYPES.OBJECT_TYPE_ID%TYPE;
  BEGIN
    IF p_nObjectTypeId IS NULL THEN
      arCheck := CanInsertObjectType(p_strCode            => p_strCode,
                                     p_strReference       => p_strReference,
                                     p_nIsDefault         => p_nIsDefault,
                                     p_strHeatingBaseTemp => p_strHeatingBaseTemp,
                                     p_strCoolingBaseTemp => p_strCoolingBaseTemp);

    ELSE
      arCheck := CanUpdateObjectType(p_nObjectTypeId      => p_nObjectTypeId,
                                     p_strCode            => p_strCode,
                                     p_strReference       => p_strReference,
                                     p_nIsDefault         => p_nIsDefault,
                                     p_strHeatingBaseTemp => p_strHeatingBaseTemp,
                                     p_strCoolingBaseTemp => p_strCoolingBaseTemp,
                                     p_strUdiTableId      => p_strUdiTableId);
    END IF;

    IF arCheck(1) <> 1 THEN
      p_recErrors := arCheck;
      RETURN 0;
    END IF;

    IF p_nObjectTypeId IS NULL THEN
      nObjectTypeId := InsertObjectType(p_strCode            => p_strCode,
                                        p_strReference       => p_strReference,
                                        p_nIsDefault         => p_nIsDefault,
                                        p_strHeatingBaseTemp => p_strHeatingBaseTemp,
                                        p_strCoolingBaseTemp => p_strCoolingBaseTemp);
    ELSE
      UpdateObjectType(p_nObjectTypeId       => p_nObjectTypeId,
                       p_strCode             => p_strCode,
                       p_strReference        => p_strReference,
                       p_nIsDefault          => p_nIsDefault,
                       p_strHeatingBaseTemp  => p_strHeatingBaseTemp,
                       p_strCoolingBaseTemp  => p_strCoolingBaseTemp,
                       p_strUdiTableId       => p_strUdiTableId);
      nObjectTypeId := p_nObjectTypeId;
    END IF;

    RETURN nObjectTypeId;
  END SaveObjectType;

  FUNCTION CanDeleteObjectType(p_nObjectTypeId NRG_OBJECT_TYPES.OBJECT_TYPE_ID%TYPE)
    RETURN T_MESSAGE_ARRAY
  AS
    recOldVal NRG_OBJECT_TYPES%ROWTYPE;
    nDummy NUMBER;
  BEGIN
    IF NOT (PK_NRG_GENERAL.IsAuthorized('delEnergyObjectTypes') = '1') THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_NO_RIGHT_DEL_ENERGY_OBJECT_TYPES');
    END IF;

    IF p_nObjectTypeId IS NULL THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_WAS_NOT_SELECTED');
    END IF;

    BEGIN
      SELECT
        *
      INTO
        recOldVal
      FROM
        NRG_OBJECT_TYPES
      WHERE
        OBJECT_TYPE_ID = p_nObjectTypeId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_DOES_NOT_EXIST');
    END;

    IF recOldVal.IS_DEFAULT = 1 THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_ONLY_ONE_DEF_VALUE_MUST_EXIST');
    END IF;

    SELECT
      COUNT(*)
    INTO
      nDummy
    FROM
      NRG_OBJECTS O
    WHERE
      O.OBJECT_TYPE_ID = p_nObjectTypeId;

    IF nDummy > 0 THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_WITH_THIS_TYPE_EXISTS');
    END IF;

    RETURN PK_MCS_APP_MESSAGES.ReturnTrue;
  END CanDeleteObjectType;

  --Return 1 if success or 0 and filled p_recErrors when unsuccess
  FUNCTION DeleteObjectType
  (
    p_nObjectTypeId            NRG_OBJECT_TYPES.OBJECT_TYPE_ID%TYPE,
    p_recErrors     OUT NOCOPY T_MESSAGE_ARRAY
  )
    RETURN NUMBER
  AS
  BEGIN
    p_recErrors := CanDeleteObjectType(p_nObjectTypeId => p_nObjectTypeId);

    IF p_recErrors(1) <> 1 THEN
      RETURN 0;
    END IF;

    m_bAllowIUD := TRUE;
    DELETE FROM NRG_OBJECT_TYPES WHERE OBJECT_TYPE_ID = p_nObjectTypeId;
    m_bAllowIUD := FALSE;
    RETURN 1;
  END DeleteObjectType;

  --------------------------------------------
  -- table  NRG_OBJECT_STATUSES
  --------------------------------------------
  FUNCTION ObjectStatusValidation
  (
    p_nObjectStatusId NRG_OBJECT_STATUSES.OBJECT_STATUS_ID%TYPE,
    p_strCode         NRG_OBJECT_STATUSES.CODE%TYPE,
    p_strReference    NRG_OBJECT_STATUSES.REFERENCE%TYPE,
    p_nClassId        NRG_OBJECT_STATUSES.CLASS_ID%TYPE,
    p_nIsDefault      NRG_OBJECT_STATUSES.IS_DEFAULT%TYPE
  )
    RETURN T_MESSAGE_ARRAY
  AS
    nDummy NUMBER;
  BEGIN
    --checking mandatory values
    IF p_strCode IS NULL THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_STATUS_CODE_CANNOT_BE_EMPTY');
    END IF;

    IF p_strReference IS NULL THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_STATUS_REFERENCE_CANNOT_BE_EMPTY');
    END IF;

    IF p_nClassId IS NULL THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_STATUS_CLASS_CANNOT_BE_EMPTY');
    END IF;

    --checking uniqueness
    BEGIN
      SELECT
        1
      INTO
        nDummy
      FROM
        NRG_OBJECT_STATUSES
      WHERE
        UPPER(CODE) = UPPER(p_strCode) AND
        OBJECT_STATUS_ID <> NVL(p_nObjectStatusId, -1);
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_STATUS_CODE_MUST_BE_UNIQUE',
                                                            p_strCode);
    EXCEPTION
      WHEN TOO_MANY_ROWS THEN
        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_STATUS_CODE_MUST_BE_UNIQUE',
                                                              p_strCode);
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;

    BEGIN
      SELECT
        1
      INTO
        nDummy
      FROM
        NRG_OBJECT_STATUSES
      WHERE
        UPPER(CODE) = UPPER(p_strReference) AND
        OBJECT_STATUS_ID <> NVL(p_nObjectStatusId, -1);
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_STATUS_REFERENCE_MUST_BE_UNIQUE',
                                                            p_strReference);
    EXCEPTION
      WHEN TOO_MANY_ROWS THEN
        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_STATUS_REFERENCE_MUST_BE_UNIQUE',
                                                              p_strReference);
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;

    IF p_nIsDefault IS NOT NULL AND
       p_nIsDefault NOT IN (0, 1) THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_IS_DEFAULT_NOT_IN_0_1');
    END IF;
    -- FK
    IF p_nClassId IS NOT NULL THEN
      SELECT
        COUNT(*)
      INTO
        nDummy
      FROM
        NRG_OBJECT_STATUS_CLASSES
      WHERE
        OBJECT_STATUS_CLASS_ID = p_nClassId;
      IF nDummy = 0 THEN
        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_STATUS_CLASS_DOESNOT_EXISTS');
      END IF;
    END IF;

    IF p_nObjectStatusId IS NOT NULL THEN
      SELECT
        COUNT(*)
      INTO
        nDummy
      FROM
        NRG_OBJECT_STATUSES
      WHERE
        IS_DEFAULT = 1 AND
        NOT (OBJECT_STATUS_ID = p_nObjectStatusId);


      IF NVL(p_nIsDefault,0) = 0 AND nDummy = 0 THEN
          RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_STATUS_SHOULD_BE_ONE_DEFAULT_VALUE');
      END IF;
    END IF;

    RETURN PK_MCS_APP_MESSAGES.ReturnTrue;
  END ObjectStatusValidation;

  FUNCTION CanInsertObjectStatus
  (
    p_strCode                 NRG_OBJECT_STATUSES.CODE%TYPE,
    p_strReference            NRG_OBJECT_STATUSES.REFERENCE%TYPE,
    p_nClassId                NRG_OBJECT_STATUSES.CLASS_ID%TYPE,
    p_nIsDefault              NRG_OBJECT_STATUSES.IS_DEFAULT%TYPE
  )
    RETURN T_MESSAGE_ARRAY
  AS
    arRet T_MESSAGE_ARRAY;
  BEGIN
    IF NOT (PK_NRG_GENERAL.IsAuthorized('modEnergyObjectStatuses') = '1') THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_NO_RIGHT_MOD_ENERGY_OBJECTS_STATUSES');
    END IF;

    arRet := ObjectStatusValidation(p_nObjectStatusId => NULL,
                                    p_strCode         => p_strCode,
                                    p_strReference    => p_strReference,
                                    p_nClassId        => p_nClassId,
                                    p_nIsDefault      => p_nIsDefault);

    RETURN arRet;
  END CanInsertObjectStatus;

  FUNCTION InsertObjectStatus
  (
    p_strCode                 NRG_OBJECT_STATUSES.CODE%TYPE,
    p_strReference            NRG_OBJECT_STATUSES.REFERENCE%TYPE,
    p_nClassId                NRG_OBJECT_STATUSES.CLASS_ID%TYPE,
    p_nIsDefault              NRG_OBJECT_STATUSES.IS_DEFAULT%TYPE
  )
    RETURN NRG_OBJECT_STATUSES.OBJECT_STATUS_ID%TYPE
  AS
    nObjectStatusId NRG_OBJECT_STATUSES.OBJECT_STATUS_ID%TYPE;
  BEGIN
    SELECT
      NRG_OBJECT_STATUSES_GEN.NEXTVAL
    INTO
      nObjectStatusId
    FROM
      DUAL;

    m_bAllowIUD := TRUE;

    IF p_nIsDefault = 1 THEN
      UPDATE
        NRG_OBJECT_STATUSES
      SET
        IS_DEFAULT = 0
      WHERE
        IS_DEFAULT = 1;
    END IF;

    INSERT INTO
      NRG_OBJECT_STATUSES
      (
        OBJECT_STATUS_ID,
        CODE,
        REFERENCE,
        CLASS_ID,
        IS_DEFAULT
      )
    VALUES
      (nObjectStatusId, --OBJECT_STATUS_ID
       p_strCode, --CODE
       p_strReference, --REFERENCE
       p_nClassId, --CLASS_ID
       NVL(p_nIsDefault, 0) --IS_DEFAULT
                           );

    m_bAllowIUD := FALSE;

    RETURN nObjectStatusId;
  END InsertObjectStatus;

  FUNCTION CanUpdateObjectStatus
  (
    p_nObjectStatusId         NRG_OBJECT_STATUSES.OBJECT_STATUS_ID%TYPE,
    p_strCode                 NRG_OBJECT_STATUSES.CODE%TYPE,
    p_strReference            NRG_OBJECT_STATUSES.REFERENCE%TYPE,
    p_nClassId                NRG_OBJECT_STATUSES.CLASS_ID%TYPE,
    p_nIsDefault              NRG_OBJECT_STATUSES.IS_DEFAULT%TYPE
  )
    RETURN T_MESSAGE_ARRAY
  AS
    arRet T_MESSAGE_ARRAY;
    recOldVal NRG_OBJECT_STATUSES%ROWTYPE;
  nDummy    NUMBER;
  BEGIN
    IF NOT (PK_NRG_GENERAL.IsAuthorized('modEnergyObjectStatuses') = '1') THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_NO_RIGHT_MOD_ENERGY_OBJECTS_STATUSES');
    END IF;

    IF p_nObjectStatusId IS NULL THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_STATUS_WAS_NOT_SELECTED');
    END IF;

    BEGIN
      SELECT
        *
      INTO
        recOldVal
      FROM
        NRG_OBJECT_STATUSES
      WHERE
        OBJECT_STATUS_ID = p_nObjectStatusId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_STATUS_DOES_NOT_EXIST');
    END;

  IF recOldVal.CLASS_ID <> p_nClassId THEN
      -- check if the status is in use an class is changed
      BEGIN
        SELECT
          1
        INTO
          nDummy
        FROM
          NRG_OBJECTS
        WHERE
          OBJECT_STATUS_ID = p_nObjectStatusId;

        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_STATUS_CLASS_CAN_NOT_BE_CHANGED');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
        WHEN TOO_MANY_ROWS THEN
          RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_STATUS_CLASS_CAN_NOT_BE_CHANGED');
      END;
    END IF;

  /*  IF recOldVal.IS_DEFAULT = 1 AND
       p_nIsDefault = 0 THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_STATUS_ONLY_ONE_DEF_VALUE_MUST_EXIST');
    END IF;*/

    arRet := ObjectStatusValidation(p_nObjectStatusId => p_nObjectStatusId,
                                    p_strCode         => p_strCode,
                                    p_strReference    => p_strReference,
                                    p_nClassId        => p_nClassId,
                                    p_nIsDefault      => p_nIsDefault);

    RETURN arRet;
  END CanUpdateObjectStatus;

  PROCEDURE UpdateObjectStatus
  (
    p_nObjectStatusId         NRG_OBJECT_STATUSES.OBJECT_STATUS_ID%TYPE,
    p_strCode                 NRG_OBJECT_STATUSES.CODE%TYPE,
    p_strReference            NRG_OBJECT_STATUSES.REFERENCE%TYPE,
    p_nClassId                NRG_OBJECT_STATUSES.CLASS_ID%TYPE,
    p_nIsDefault              NRG_OBJECT_STATUSES.IS_DEFAULT%TYPE
  )
  AS
  BEGIN
    m_bAllowIUD := TRUE;

    IF p_nIsDefault = 1 THEN
      UPDATE
        NRG_OBJECT_STATUSES
      SET
        IS_DEFAULT = 0
      WHERE
        IS_DEFAULT = 1;
    END IF;

    UPDATE
      NRG_OBJECT_STATUSES
    SET
      CODE = p_strCode,
      REFERENCE = p_strReference,
      CLASS_ID = p_nClassId,
      IS_DEFAULT = NVL(p_nIsDefault, 0)
    WHERE
      OBJECT_STATUS_ID = p_nObjectStatusId;

    m_bAllowIUD := FALSE;
  END UpdateObjectStatus;

  FUNCTION SaveObjectStatus
  (
    p_nObjectStatusId                      NRG_OBJECT_STATUSES.OBJECT_STATUS_ID%TYPE,
    p_strCode                              NRG_OBJECT_STATUSES.CODE%TYPE,
    p_strReference                         NRG_OBJECT_STATUSES.REFERENCE%TYPE,
    p_nClassId                             NRG_OBJECT_STATUSES.CLASS_ID%TYPE,
    p_nIsDefault                           NRG_OBJECT_STATUSES.IS_DEFAULT%TYPE,
    p_recErrors                 OUT NOCOPY T_MESSAGE_ARRAY
  )
    RETURN NRG_OBJECT_STATUSES.OBJECT_STATUS_ID%TYPE
  AS
    arCheck T_MESSAGE_ARRAY;
    nObjectStatusId NRG_OBJECT_STATUSES.OBJECT_STATUS_ID%TYPE;
  BEGIN
    IF p_nObjectStatusId IS NULL THEN
      arCheck := CanInsertObjectStatus(p_strCode      => p_strCode,
                                       p_strReference => p_strReference,
                                       p_nClassId     => p_nClassId,
                                       p_nIsDefault   => p_nIsDefault);
    ELSE
      arCheck := CanUpdateObjectStatus(p_nObjectStatusId => p_nObjectStatusId,
                                       p_strCode         => p_strCode,
                                       p_strReference    => p_strReference,
                                       p_nClassId        => p_nClassId,
                                       p_nIsDefault      => p_nIsDefault);
    END IF;

    IF arCheck(1) <> 1 THEN
      p_recErrors := arCheck;
      RETURN 0;
    END IF;

    IF p_nObjectStatusId IS NULL THEN
      nObjectStatusId := InsertObjectStatus(p_strCode      => p_strCode,
                                            p_strReference => p_strReference,
                                            p_nClassId     => p_nClassId,
                                            p_nIsDefault   => p_nIsDefault);
    ELSE
      UpdateObjectStatus(p_nObjectStatusId => p_nObjectStatusId,
                         p_strCode         => p_strCode,
                         p_strReference    => p_strReference,
                         p_nClassId        => p_nClassId,
                         p_nIsDefault      => p_nIsDefault);
      nObjectStatusId := p_nObjectStatusId;
    END IF;

    RETURN nObjectStatusId;
  END SaveObjectStatus;

  FUNCTION CanDeleteObjectStatus
  (
    p_nObjectStatusId NRG_OBJECT_STATUSES.OBJECT_STATUS_ID%TYPE
  )
    RETURN T_MESSAGE_ARRAY
  AS
    recOldVal NRG_OBJECT_STATUSES%ROWTYPE;
    nDummy NUMBER;
  BEGIN
    IF NOT (PK_NRG_GENERAL.IsAuthorized('delEnergyObjectStatuses') = '1') THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_NO_RIGHT_DEL_ENERGY_OBJECT_STATUSES');
    END IF;

    IF p_nObjectStatusId IS NULL THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_STATUS_WAS_NOT_SELECTED');
    END IF;

    BEGIN
      SELECT
        *
      INTO
        recOldVal
      FROM
        NRG_OBJECT_STATUSES
      WHERE
        OBJECT_STATUS_ID = p_nObjectStatusId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_STATUS_DOES_NOT_EXIST');
    END;

    IF recOldVal.IS_DEFAULT = 1 THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_STATUS_ONLY_ONE_DEF_VALUE_MUST_EXIST');
    END IF;

    SELECT
      COUNT(*)
    INTO
      nDummy
    FROM
      NRG_OBJECTS O
    WHERE
      O.OBJECT_STATUS_ID = p_nObjectStatusId;

    IF nDummy > 0 THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_WITH_THIS_STATUS_EXISTS');
    END IF;

    RETURN PK_MCS_APP_MESSAGES.ReturnTrue;
  END CanDeleteObjectStatus;

  --Return 1 if success or 0 and filled p_recErrors when unsuccess
  FUNCTION DeleteObjectStatus
  (
    p_nObjectStatusId                      NRG_OBJECT_STATUSES.OBJECT_STATUS_ID%TYPE,
    p_recErrors                 OUT NOCOPY T_MESSAGE_ARRAY
  )
    RETURN NUMBER
  AS
  BEGIN
    p_recErrors := CanDeleteObjectStatus(p_nObjectStatusId => p_nObjectStatusId);

    IF p_recErrors(1) <> 1 THEN
      RETURN 0;
    END IF;

    m_bAllowIUD := TRUE;
    DELETE FROM
      NRG_OBJECT_STATUSES
    WHERE
      OBJECT_STATUS_ID = p_nObjectStatusId;
    m_bAllowIUD := FALSE;
    RETURN 1;
  END DeleteObjectStatus;

  --------------------------------------------
  -- table  NRG_OBJECTS
  --------------------------------------------
  FUNCTION ObjectValidation
  (
    p_nObjectId               NRG_OBJECTS.OBJECT_ID%TYPE,
    p_strCode                 NRG_OBJECTS.CODE%TYPE,
    p_strReference            NRG_OBJECTS.REFERENCE%TYPE,
    p_nObjectTypeId           NRG_OBJECTS.OBJECT_TYPE_ID%TYPE,
    p_strSiteId               NRG_OBJECTS.SITE_ID%TYPE,
    p_nParentObjectId         NRG_OBJECTS.PARENT_OBJECT_ID%TYPE,
    p_strLocationId           NRG_OBJECTS.LOCATION_ID%TYPE,
    p_nObjectStatusId         NRG_OBJECTS.OBJECT_STATUS_ID%TYPE,
    p_strClientOrganizationId NRG_OBJECTS.CLIENT_ORGANIZATION_ID%TYPE,
    p_strResourceId           NRG_OBJECTS.RESOURCE_ID%TYPE
  )
    RETURN T_MESSAGE_ARRAY
  AS
    nDummy NUMBER;
    nParentObjectId NRG_OBJECTS.PARENT_OBJECT_ID%TYPE;
  BEGIN
    --checking mandatory values
    IF p_strCode IS NULL THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_OBJ_CODE_CANNOT_BE_EMPTY');
    END IF;

    IF p_strReference IS NULL THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_OBJ_REFERENCE_CANNOT_BE_EMPTY');
    END IF;

    IF p_nObjectTypeId IS NULL THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_OBJ_TYPE_CANNOT_BE_EMPTY');
    END IF;

    IF p_strSiteId IS NULL THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_OBJ_SITE_CANNOT_BE_EMPTY');
    END IF;

    IF p_nObjectStatusId IS NULL THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_OBJ_STATUS_CANNOT_BE_EMPTY');
    END IF;

    --checking uniqueness
    BEGIN
      SELECT
        1
      INTO
        nDummy
      FROM
        NRG_OBJECTS
      WHERE
        UPPER(CODE) = UPPER(p_strCode) AND
        SITE_ID = p_strSiteId AND
        OBJECT_ID <> NVL(p_nObjectId, -1);
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_OBJ_CODE_MUST_BE_UNIQUE',
                                                            p_strCode);
    EXCEPTION
      WHEN TOO_MANY_ROWS THEN
        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_OBJ_CODE_MUST_BE_UNIQUE',
                                                              p_strCode);
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;

    BEGIN
      SELECT
        1
      INTO
        nDummy
      FROM
        NRG_OBJECTS
      WHERE
        UPPER(REFERENCE) = UPPER(p_strReference) AND
        SITE_ID = p_strSiteId AND
        OBJECT_ID <> NVL(p_nObjectId, -1);
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_OBJ_REFERENCE_MUST_BE_UNIQUE',
                                                            p_strReference);
    EXCEPTION
      WHEN TOO_MANY_ROWS THEN
        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECTS_OBJ_REFERENCE_MUST_BE_UNIQUE',
                                                              p_strReference);
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;

    -- FK
    IF p_nObjectTypeId IS NOT NULL THEN
      SELECT
        COUNT(*)
      INTO
        nDummy
      FROM
        NRG_OBJECT_TYPES
      WHERE
        OBJECT_TYPE_ID = p_nObjectTypeId;
      IF nDummy = 0 THEN
        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_OBJ_TYPE_DOESNOT_EXISTS');
      END IF;
    END IF;

    IF p_strSiteId IS NOT NULL THEN
      SELECT
        COUNT(*)
      INTO
        nDummy
      FROM
        LOCATIONS
      WHERE
        LOCATION_ID = p_strSiteId AND
        LOCATION_TYPE = 'SITE';
      IF nDummy = 0 THEN
        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_OBJ_SITE_DOESNOT_EXISTS');
      END IF;
    END IF;

    IF p_nParentObjectId IS NOT NULL THEN
      SELECT
        COUNT(*)
      INTO
        nDummy
      FROM
        NRG_OBJECTS
      WHERE
        OBJECT_ID = p_nParentObjectId;
      IF nDummy = 0 THEN
        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_PARENT_OBJ_DOESNOT_EXISTS');
      END IF;
    END IF;

    IF p_strLocationId IS NOT NULL THEN
      SELECT
        COUNT(*)
      INTO
        nDummy
      FROM
        LOCATIONS
      WHERE
        LOCATION_ID = p_strLocationId;
      IF nDummy = 0 THEN
        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_OBJ_LOCATION_DOESNOT_EXISTS');
      END IF;
    END IF;

    IF p_nObjectStatusId IS NOT NULL THEN
      SELECT
        COUNT(*)
      INTO
        nDummy
      FROM
        NRG_OBJECT_STATUSES
      WHERE
        OBJECT_STATUS_ID = p_nObjectStatusId;
      IF nDummy = 0 THEN
        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_OBJ_STATUS_DOESNOT_EXISTS');
      END IF;
    END IF;

    IF p_strClientOrganizationId IS NOT NULL THEN
      SELECT
        COUNT(*)
      INTO
        nDummy
      FROM
        CLIENT_ORGANIZATIONS
      WHERE
        CLIENT_ORGANIZATION_ID = p_strClientOrganizationId;
      IF nDummy = 0 THEN
        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_OBJ_CLIENT_ORG_DOESNOT_EXISTS');
      END IF;
    END IF;

    --
    IF p_nObjectId IS NOT NULL THEN
      BEGIN
        SELECT
          NVL(N.Parent_Object_Id, 0)
        INTO
          nParentObjectId
        FROM
          NRG_OBJECTS N
        WHERE
          N.OBJECT_ID = p_nObjectId AND
          N.PARENT_OBJECT_ID IS NOT NULL;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          nParentObjectId := 0;
      END;

      IF nParentObjectId <> p_nParentObjectId AND
         p_nParentObjectId IS NOT NULL AND
         nParentObjectId <> 0 THEN
        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_PARENT_OBJ_CANNOT_BE_CHANGE');
      END IF;
    END IF;

    IF p_strSiteId IS NOT NULL AND
       p_strClientOrganizationId IS NOT NULL THEN
      SELECT
        COUNT(*)
      INTO
        nDummy
      FROM
        CLIENT_ORGANIZATIONS CO
      WHERE
        CO.CLIENT_ORGANIZATION_ID = p_strClientOrganizationId AND
        EXISTS
          (SELECT
             1
           FROM
             SITE_CUSTOMER_LINK LNK,
             EXTERNALS C
           WHERE
             LNK.EXTERNAL_ID = C.EXTERNAL_ID AND
             C.CLIENT_ORGANIZATION_ID = CO.CLIENT_ORGANIZATION_ID AND
             LNK.SITE_ID = p_strSiteId);
      IF nDummy = 0 THEN
        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJ_CLIENT_ORG_DOESNOT_LINK_PARENT_SITE');
      END IF;
    END IF;

    IF p_nParentObjectId IS NOT NULL THEN
      SELECT
        COUNT(*)
      INTO
        nDummy
      FROM
        NRG_OBJECTS
      WHERE
        OBJECT_ID = p_nParentObjectId AND
        SITE_ID = p_strSiteId;
      IF nDummy = 0 THEN
        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_PARENT_OBJ_NOT_LINK_ON_SITE');
      END IF;
    END IF;

    RETURN PK_MCS_APP_MESSAGES.ReturnTrue;
  END ObjectValidation;

  FUNCTION CanInsertObject
  (
    p_strCode                 NRG_OBJECTS.CODE%TYPE,
    p_strReference            NRG_OBJECTS.REFERENCE%TYPE,
    p_nObjectTypeId           NRG_OBJECTS.OBJECT_TYPE_ID%TYPE,
    p_strSiteId               NRG_OBJECTS.SITE_ID%TYPE,
    p_nParentObjectId         NRG_OBJECTS.PARENT_OBJECT_ID%TYPE,
    p_strLocationId           NRG_OBJECTS.LOCATION_ID%TYPE,
    p_nObjectStatusId         NRG_OBJECTS.OBJECT_STATUS_ID%TYPE,
    p_strClientOrganizationId NRG_OBJECTS.CLIENT_ORGANIZATION_ID%TYPE,
    p_strResourceId           NRG_OBJECTS.RESOURCE_ID%TYPE
  )
    RETURN T_MESSAGE_ARRAY
  AS
    arRet T_MESSAGE_ARRAY;
  BEGIN
    IF NOT (PK_NRG_GENERAL.IsAuthorized('modEnergyObjects') = '1') THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_NO_RIGHT_MOD_ENERGY_OBJECTS');
    END IF;

    --check specific rights for parent EO
    IF p_nParentObjectId IS NOT NULL THEN
      arRet := pk_nrg_check_specific_rights.get_nrg_object_rights(p_nobjectid => p_nParentObjectId);
      IF arRet(1) <> 1 THEN
        RETURN arRet;
      END IF;
    END IF;

    arRet := ObjectValidation(p_nObjectId               => NULL,
                              p_strCode                 => p_strCode,
                              p_strReference            => p_strReference,
                              p_nObjectTypeId           => p_nObjectTypeId,
                              p_strSiteId               => p_strSiteId,
                              p_nParentObjectId         => p_nParentObjectId,
                              p_strLocationId           => p_strLocationId,
                              p_nObjectStatusId         => p_nObjectStatusId,
                              p_strClientOrganizationId => p_strClientOrganizationId,
                              p_strResourceId           => p_strResourceId);
    RETURN arRet;
  END CanInsertObject;

  FUNCTION InsertObject
  (
    p_strCode                 NRG_OBJECTS.CODE%TYPE,
    p_strReference            NRG_OBJECTS.REFERENCE%TYPE,
    p_strDescription          NRG_OBJECTS.DESCRIPTION%TYPE,
    p_nObjectTypeId           NRG_OBJECTS.OBJECT_TYPE_ID%TYPE,
    p_strSiteId               NRG_OBJECTS.SITE_ID%TYPE,
    p_nParentObjectId         NRG_OBJECTS.PARENT_OBJECT_ID%TYPE,
    p_strLocationId           NRG_OBJECTS.LOCATION_ID%TYPE,
    p_nObjectStatusId         NRG_OBJECTS.OBJECT_STATUS_ID%TYPE,
    p_strClientOrganizationId NRG_OBJECTS.CLIENT_ORGANIZATION_ID%TYPE,
    p_strResourceId           NRG_OBJECTS.RESOURCE_ID%TYPE
  )
    RETURN NRG_OBJECTS.OBJECT_ID%TYPE
  AS
    nObjectId NRG_OBJECTS.OBJECT_ID%TYPE;
  BEGIN
    SELECT
      NRG_OBJECTS_GEN.NEXTVAL
    INTO
      nObjectId
    FROM
      DUAL;

    dtCurdate := CURRENT_TIMESTAMP;
    strCurAccountId := PK_AUDIT.GET_CURRENT_ACCOUNT;

    m_bAllowIUD := TRUE;

    INSERT INTO
      NRG_OBJECTS
      (
        OBJECT_ID,
        CODE,
        REFERENCE,
        DESCRIPTION,
        OBJECT_TYPE_ID,
        SITE_ID,
        PARENT_OBJECT_ID,
        LOCATION_ID,
        OBJECT_STATUS_ID,
        CLIENT_ORGANIZATION_ID,
        RESOURCE_ID,
        CREATION_DATE,
        CREATION_ACCOUNT_ID,
        LATEST_MOD_DATE,
        LATEST_MOD_ACCOUNT_ID
      )
    VALUES
      (nObjectId,
       p_strCode,
       p_strReference,
       p_strDescription,
       p_nObjectTypeId,
       p_strSiteId,
       p_nParentObjectId,
       p_strLocationId,
       p_nObjectStatusId,
       p_strClientOrganizationId,
       p_strResourceId,
       dtCurdate,
       strCurAccountId,
       dtCurdate,
       strCurAccountId);

    m_bAllowIUD := FALSE;

    PK_PM_WORKING_TIMES.InsertResource('ENERGY_OBJECT', nObjectId);

    RETURN nObjectId;
  END InsertObject;

  FUNCTION CanUpdateObject
  (
    p_nObjectId               NRG_OBJECTS.OBJECT_ID%TYPE,
    p_strCode                 NRG_OBJECTS.CODE%TYPE,
    p_strReference            NRG_OBJECTS.REFERENCE%TYPE,
    p_nObjectTypeId           NRG_OBJECTS.OBJECT_TYPE_ID%TYPE,
    p_strSiteId               NRG_OBJECTS.SITE_ID%TYPE,
    p_nParentObjectId         NRG_OBJECTS.PARENT_OBJECT_ID%TYPE,
    p_strLocationId           NRG_OBJECTS.LOCATION_ID%TYPE,
    p_nObjectStatusId         NRG_OBJECTS.OBJECT_STATUS_ID%TYPE,
    p_strClientOrganizationId NRG_OBJECTS.CLIENT_ORGANIZATION_ID%TYPE,
    p_strResourceId           NRG_OBJECTS.RESOURCE_ID%TYPE
  )
    RETURN T_MESSAGE_ARRAY
  AS
    arRet T_MESSAGE_ARRAY;
    nDummy NUMBER;
  BEGIN
    IF NOT (PK_NRG_GENERAL.IsAuthorized('modEnergyObjects') = '1') THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_NO_RIGHT_MOD_ENERGY_OBJECTS');
    END IF;

    IF p_nObjectId IS NULL THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_OBJ_WAS_NOT_SELECTED');
    END IF;

    SELECT
      COUNT(*)
    INTO
      nDummy
    FROM
      NRG_OBJECTS
    WHERE
      OBJECT_ID = p_nObjectId;

    IF nDummy = 0 THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_OBJ_DOES_NOT_EXIST');
    END IF;

    --check specific rights for parent EO
    IF p_nParentObjectId IS NOT NULL THEN
      arRet := pk_nrg_check_specific_rights.get_nrg_object_rights(p_nobjectid => p_nParentObjectId);
      IF arRet(1) <> 1 THEN
        RETURN arRet;
      END IF;
    END IF;

    IF p_nObjectId IS NOT NULL THEN
      arRet := pk_nrg_check_specific_rights.get_nrg_object_rights(p_nobjectid => p_nObjectId);
      IF arRet(1) <> 1 THEN
        RETURN arRet;
      END IF;
    END IF;

    arRet := ObjectValidation(p_nObjectId               => p_nObjectId,
                              p_strCode                 => p_strCode,
                              p_strReference            => p_strReference,
                              p_nObjectTypeId           => p_nObjectTypeId,
                              p_strSiteId               => p_strSiteId,
                              p_nParentObjectId         => p_nParentObjectId,
                              p_strLocationId           => p_strLocationId,
                              p_nObjectStatusId         => p_nObjectStatusId,
                              p_strClientOrganizationId => p_strClientOrganizationId,
                              p_strResourceId           => p_strResourceId);
    RETURN arRet;
  END CanUpdateObject;

  PROCEDURE UpdateObject
  (
    p_nObjectId               NRG_OBJECTS.OBJECT_ID%TYPE,
    p_strCode                 NRG_OBJECTS.CODE%TYPE,
    p_strReference            NRG_OBJECTS.REFERENCE%TYPE,
    p_strDescription          NRG_OBJECTS.DESCRIPTION%TYPE,
    p_nObjectTypeId           NRG_OBJECTS.OBJECT_TYPE_ID%TYPE,
    p_strSiteId               NRG_OBJECTS.SITE_ID%TYPE,
    p_nParentObjectId         NRG_OBJECTS.PARENT_OBJECT_ID%TYPE,
    p_strLocationId           NRG_OBJECTS.LOCATION_ID%TYPE,
    p_nObjectStatusId         NRG_OBJECTS.OBJECT_STATUS_ID%TYPE,
    p_strClientOrganizationId NRG_OBJECTS.CLIENT_ORGANIZATION_ID%TYPE,
    p_strResourceId           NRG_OBJECTS.RESOURCE_ID%TYPE
  )
  AS
  BEGIN
    dtCurdate := CURRENT_TIMESTAMP;
    strCurAccountId := PK_AUDIT.GET_CURRENT_ACCOUNT;
    m_bAllowIUD := TRUE;

    UPDATE
      NRG_OBJECTS
    SET
      CODE = p_strCode,
      REFERENCE = p_strReference,
      DESCRIPTION = p_strDescription,
      OBJECT_TYPE_ID = p_nObjectTypeId,
      SITE_ID = p_strSiteId,
      PARENT_OBJECT_ID = p_nParentObjectId,
      LOCATION_ID = p_strLocationId,
      OBJECT_STATUS_ID = p_nObjectStatusId,
      CLIENT_ORGANIZATION_ID = p_strClientOrganizationId,
      RESOURCE_ID = p_strResourceId,
      LATEST_MOD_DATE = dtCurdate,
      LATEST_MOD_ACCOUNT_ID = strCurAccountId
    WHERE
      OBJECT_ID = p_nObjectId;

    m_bAllowIUD := FALSE;
  END UpdateObject;

  FUNCTION SaveObject
  (
    p_nObjectId                            NRG_OBJECTS.OBJECT_ID%TYPE,
    p_strCode                              NRG_OBJECTS.CODE%TYPE,
    p_strReference                         NRG_OBJECTS.REFERENCE%TYPE,
    p_strDescription                       NRG_OBJECTS.DESCRIPTION%TYPE,
    p_nObjectTypeId                        NRG_OBJECTS.OBJECT_TYPE_ID%TYPE,
    p_strSiteId                            NRG_OBJECTS.SITE_ID%TYPE,
    p_nParentObjectId                      NRG_OBJECTS.PARENT_OBJECT_ID%TYPE,
    p_strLocationId                        NRG_OBJECTS.LOCATION_ID%TYPE,
    p_nObjectStatusId                      NRG_OBJECTS.OBJECT_STATUS_ID%TYPE,
    p_strClientOrganizationId              NRG_OBJECTS.CLIENT_ORGANIZATION_ID%TYPE,
    p_strResourceId                        NRG_OBJECTS.RESOURCE_ID%TYPE,
    p_recErrors                 OUT NOCOPY T_MESSAGE_ARRAY
  )
    RETURN NRG_OBJECTS.OBJECT_ID%TYPE
  AS
    arCheck T_MESSAGE_ARRAY;
    nObjectId NRG_OBJECTS.OBJECT_ID%TYPE;
  BEGIN
    IF p_nObjectId IS NULL THEN
      arCheck := CanInsertObject(p_strCode                 => p_strCode,
                                 p_strReference            => p_strReference,
                                 p_nObjectTypeId           => p_nObjectTypeId,
                                 p_strSiteId               => p_strSiteId,
                                 p_nParentObjectId         => p_nParentObjectId,
                                 p_strLocationId           => p_strLocationId,
                                 p_nObjectStatusId         => p_nObjectStatusId,
                                 p_strClientOrganizationId => p_strClientOrganizationId,
                                 p_strResourceId           => p_strResourceId);
    ELSE
      arCheck := CanUpdateObject(p_nObjectId               => p_nObjectId,
                                 p_strCode                 => p_strCode,
                                 p_strReference            => p_strReference,
                                 p_nObjectTypeId           => p_nObjectTypeId,
                                 p_strSiteId               => p_strSiteId,
                                 p_nParentObjectId         => p_nParentObjectId,
                                 p_strLocationId           => p_strLocationId,
                                 p_nObjectStatusId         => p_nObjectStatusId,
                                 p_strClientOrganizationId => p_strClientOrganizationId,
                                 p_strResourceId           => p_strResourceId);
    END IF;

    IF arCheck(1) <> 1 THEN
      p_recErrors := arCheck;
      RETURN 0;
    END IF;

    IF p_nObjectId IS NULL THEN
      nObjectId := InsertObject(p_strCode                 => p_strCode,
                                p_strReference            => p_strReference,
                                p_strDescription          => p_strDescription,
                                p_nObjectTypeId           => p_nObjectTypeId,
                                p_strSiteId               => p_strSiteId,
                                p_nParentObjectId         => p_nParentObjectId,
                                p_strLocationId           => p_strLocationId,
                                p_nObjectStatusId         => p_nObjectStatusId,
                                p_strClientOrganizationId => p_strClientOrganizationId,
                                p_strResourceId           => p_strResourceId);
    ELSE
      UpdateObject(p_nObjectId               => p_nObjectId,
                   p_strCode                 => p_strCode,
                   p_strReference            => p_strReference,
                   p_strDescription          => p_strDescription,
                   p_nObjectTypeId           => p_nObjectTypeId,
                   p_strSiteId               => p_strSiteId,
                   p_nParentObjectId         => p_nParentObjectId,
                   p_strLocationId           => p_strLocationId,
                   p_nObjectStatusId         => p_nObjectStatusId,
                   p_strClientOrganizationId => p_strClientOrganizationId,
                   p_strResourceId           => p_strResourceId);
      nObjectId := p_nObjectId;
    END IF;

    RETURN nObjectId;
  END SaveObject;

  FUNCTION CanDeleteObject(p_nObjectId NRG_OBJECTS.OBJECT_ID%TYPE)
    RETURN T_MESSAGE_ARRAY
  AS
    nDummy NUMBER;
    arRet T_MESSAGE_ARRAY;
  BEGIN
    IF NOT (PK_NRG_GENERAL.IsAuthorized('delEnergyObjects') = '1') THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_NO_RIGHT_DEL_ENERGY_OBJECTS');
    END IF;

    IF p_nObjectId IS NULL THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_OBJ_WAS_NOT_SELECTED');
    END IF;

    SELECT
      COUNT(*)
    INTO
      nDummy
    FROM
      NRG_OBJECTS
    WHERE
      OBJECT_ID = p_nObjectId;

    IF nDummy = 0 THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_OBJ_DOES_NOT_EXIST');
    END IF;

    SELECT
      COUNT(*)
    INTO
      nDummy
    FROM
      NRG_OBJECTS
    WHERE
      PARENT_OBJECT_ID = p_nObjectId;

    IF nDummy > 0 THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_OBJ_NO_DEL_HAS_CHILD');
    END IF;

    SELECT
      COUNT(*)
    INTO
      nDummy
    FROM
      NRG_SUPPLY_POINTS SP
    WHERE
      SP.OBJECT_ID = p_nObjectId;

    IF nDummy > 0 THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_OBJ_NO_DEL_HAS_SUPPLY_POINT');
    END IF;

    SELECT
      COUNT(*)
    INTO
      nDummy
    FROM
      NRG_METERS EM,
      NRG_OBJECTS EO,
      NRG_CHANNEL_CLASSES NCS
    WHERE
      EM.CLASS_ID = NCS.CHANNEL_CLASS_ID AND
      EO.OBJECT_ID = EM.SCOPE_OBJECT_ID AND
      NCS.CODE = 'Energy Gauge' AND
      EO.OBJECT_ID = p_nObjectId;

    IF nDummy > 0 THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_OBJ_NO_DEL_HAS_GAUGE');
    END IF;

    BEGIN
      SELECT
        1
      INTO
        nDummy
      FROM
        NRG_SUPPLY_POINTS
      WHERE
        OBJECT_ID = p_nObjectId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN TOO_MANY_ROWS THEN
        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_OBJ_NO_DEL_HAS_LINKED_SUPPLY_POINT');
    END;
    --check if Object is in Measures scope
    SELECT
      COUNT(*)
    INTO
      nDummy
    FROM
      NRG_MEASURES
    WHERE
      OBJECT_ID = p_nObjectId;

    IF nDummy > 0 THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_OBJ_NO_DEL_HAS_LINKED_MEASURES');
    END IF;
    --check if Object is in EO scope
    SELECT
      COUNT(*)
    INTO
      nDummy
    FROM
      PROJECTS
    WHERE
      OBJECT_ID = p_nObjectId;

    IF nDummy > 0 THEN
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_OBJ_NO_DEL_HAS_LINKED_PROJECTS');
    END IF;
    --check if Object is in Meter/Collector scope
    BEGIN
      SELECT
        1
      INTO
        nDummy
      FROM
        NRG_SCOPE_ITEMS SI
      WHERE
        SI.OBJECT_ID = p_nObjectId;
      RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_OBJ_NO_DEL_TAKES_PART_IN_SCOPE');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN TOO_MANY_ROWS THEN
        RETURN PK_MCS_APP_MESSAGES.GET_MCS_APP_MESSAGE_ID_EXT('NRG_DB_OBJECT_OBJ_NO_DEL_TAKES_PART_IN_SCOPE');
    END;

    --check specific rights for parent EO
    IF p_nObjectId IS NOT NULL THEN
      arRet := pk_nrg_check_specific_rights.get_nrg_object_rights(p_nobjectid => p_nObjectId);
      IF arRet(1) <> 1 THEN
        RETURN arRet;
      END IF;
    END IF;

    RETURN PK_MCS_APP_MESSAGES.ReturnTrue;
  END CanDeleteObject;

  --Return 1 if success or 0 and filled p_recErrors when unsuccess
  FUNCTION DeleteObject
  (
    p_nObjectId NRG_OBJECTS.OBJECT_ID%TYPE,
    p_recErrors OUT NOCOPY T_MESSAGE_ARRAY
  )
    RETURN NUMBER
  AS
  BEGIN
    p_recErrors := CanDeleteObject(p_nObjectId => p_nObjectId);

    IF p_recErrors(1) <> 1 THEN
      RETURN 0;
    END IF;

    m_bAllowIUD := TRUE;
    DELETE FROM
      NRG_OBJECTS
    WHERE
      OBJECT_ID = p_nObjectId;
    m_bAllowIUD := FALSE;
    RETURN 1;
  END DeleteObject;

END PK_NRG_OBJECTS;