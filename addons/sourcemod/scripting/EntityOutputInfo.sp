#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

// Struct layouts depend on the pointer size: the offsets that move are variables
// set by InitStructOffsets() (SM 1.13 cannot initialize a global Address).

// datamap_t
#define dataDesc_offset         view_as<Address>(0x00)
Address dataNumFields_offset;
Address baseMap_offset;
#define FTYPEDESC_OUTPUT        0x0010

// typedescription_t
#define fieldType_offset        view_as<Address>(0x00)
Address fieldName_offset;
Address flags_offset;
// Differs per platform too (member function pointer size): read from gamedata
int typedescription_t_size      = -1;

// varianthax_t m_Value
#define Union_Val_offset        view_as<Address>(0x00)
Address fieldType_var_offset;

// CBaseEntityOutput
#define m_Value_offset          view_as<Address>(0x00)
Address m_ActionList_offset;

// CEventAction
#define m_iTarget_offset        view_as<Address>(0x00)
Address m_iTargetInput_offset;
Address m_iParameter_offset;
Address m_flDelay_offset;
Address m_nTimesToFire_offset;
Address m_pNext_offset;

/**
 * Field types used in Source Engine datamaps (fieldtype_t).
 * Mirrors the engine enum defined in datamap.h.
 */
enum
{
	FIELD_VOID = 0,                 // No type or value
	FIELD_FLOAT,                    // Any floating point value
	FIELD_STRING,                   // A string ID (returned from ALLOC_STRING)
	FIELD_VECTOR,                   // Any vector, QAngle, or AngularImpulse
	FIELD_QUATERNION,               // A quaternion
	FIELD_INTEGER,                  // Any integer or enum
	FIELD_BOOLEAN,                  // Boolean, implemented as an int
	FIELD_SHORT,                    // 2-byte integer
	FIELD_CHARACTER,                // A single byte
	FIELD_COLOR32,                  // 8-bit per channel RGBA (32-bit color)
	FIELD_EMBEDDED,                 // Embedded object with a datadesc; recursively traversed
	FIELD_CUSTOM,                   // Special type with function pointers for read/write/parse

	FIELD_CLASSPTR,                 // CBaseEntity*
	FIELD_EHANDLE,                  // Entity handle
	FIELD_EDICT,                    // edict_t*

	FIELD_POSITION_VECTOR,          // World coordinate (fixed up across level transitions)
	FIELD_TIME,                     // Floating point time (fixed up automatically)
	FIELD_TICK,                     // Integer tick count (fixed up similarly to time)
	FIELD_MODELNAME,                // Engine string representing a model name (needs precache)
	FIELD_SOUNDNAME,                // Engine string representing a sound name (needs precache)

	FIELD_INPUT,                    // List of input data fields (derived from CMultiInputVar)
	FIELD_FUNCTION,                 // Class function pointer (Think, Use, etc.)

	FIELD_VMATRIX,                  // VMatrix (output coords are NOT worldspace)
	FIELD_VMATRIX_WORLDSPACE,       // VMatrix mapping local space to world space (translation fixed up on level transitions)
	FIELD_MATRIX3X4_WORLDSPACE,     // matrix3x4_t mapping local space to world space (translation fixed up on level transitions)

	FIELD_INTERVAL,                 // Start and range floating point interval (e.g. 3.2->3.6 == 3.2 and 0.4)
	FIELD_MODELINDEX,               // A model index
	FIELD_MATERIALINDEX,            // A material index (using the material precache string table)

	FIELD_VECTOR2D,                 // 2D vector (2 floats)

	FIELD_TYPECOUNT,                // MUST BE LAST
};

Handle g_hDeleteElement;
Handle g_hGetDataDescMap;

public Plugin myinfo =
{
	name		= "Entity Output Info",
	author		= "Botox, Addie, Dolly, .Rushaway",
	description	= "Advanced entity output manipulation API",
	version		= "1.2.6",
	url			= "https://github.com/srcdslab"
};

public APLRes AskPluginLoad2(Handle myPlugin, bool late, char[] error, int err_max)
{
	CreateNative("GetOutputCount", Native_GetOutputCount);
	CreateNative("GetOutputTarget", Native_GetOutputTarget);
	CreateNative("GetOutputTargetInput", Native_GetOutputTargetInput);
	CreateNative("GetOutputParameter", Native_GetOutputParameter);
	CreateNative("GetOutputDelay", Native_GetOutputDelay);
	CreateNative("GetOutputRefires", Native_GetOutputRefires);
	CreateNative("GetOutputValue", Native_GetOutputValue);
	CreateNative("GetOutputValueFloat", Native_GetOutputValueFloat);
	CreateNative("GetOutputValueString", Native_GetOutputValueString);
	CreateNative("GetOutputValueVector", Native_GetOutputValueVector);
	CreateNative("FindOutput", Native_FindOutput);
	CreateNative("DeleteOutput", Native_DeleteOutput);
	CreateNative("DeleteAllOutputs", Native_DeleteAllOutputs);

	CreateNative("GetOutputFormatted", Native_GetOutputFormatted);
	CreateNative("GetOutputNames", Native_GetOutputNames);

	RegPluginLibrary("EntityOutputInfo");
	return APLRes_Success;
}

int Native_GetOutputCount(Handle plugin, int params)
{
	int entity = GetNativeCell(1);
	if (!IsValidEntity(entity))
		return ThrowNativeError(0, "Entity '%d' is invalid.", entity);

	char output[256];
	GetNativeString(2, output, sizeof(output));

	return GetOutputCount(entity, output);
}

int Native_GetOutputTarget(Handle plugin, int params)
{
	int entity = GetNativeCell(1);
	if (!IsValidEntity(entity))
		return ThrowNativeError(0, "Entity '%d' is invalid.", entity);

	char output[256];
	GetNativeString(2, output, sizeof(output));

	int index = GetNativeCell(3);
	if (index < 0)
		return ThrowNativeError(0, "Index '%d' is invalid.", index);

	int maxlen = GetNativeCell(5);

	char[] target = new char[maxlen];
	GetNativeString(4, target, maxlen);

	int len = GetOutputTarget(entity, output, index, target, maxlen);
	if (len)
		SetNativeString(4, target, maxlen);

	return len;
}

int Native_GetOutputTargetInput(Handle plugin, int params)
{
	int entity = GetNativeCell(1);
	if (!IsValidEntity(entity))
		return ThrowNativeError(0, "Entity '%d' is invalid.", entity);

	char output[256];
	GetNativeString(2, output, sizeof(output));

	int index = GetNativeCell(3);
	if (index < 0)
		return ThrowNativeError(0, "Index '%d' is invalid.", index);

	int maxlen = GetNativeCell(5);

	char[] targetInput = new char[maxlen];
	GetNativeString(4, targetInput, maxlen);

	int len = GetOutputTargetInput(entity, output, index, targetInput, maxlen);
	if (len)
		SetNativeString(4, targetInput, maxlen);

	return len;
}

int Native_GetOutputParameter(Handle plugin, int params)
{
	int entity = GetNativeCell(1);
	if (!IsValidEntity(entity))
		return ThrowNativeError(0, "Entity '%d' is invalid.", entity);

	char output[256];
	GetNativeString(2, output, sizeof(output));

	int index = GetNativeCell(3);
	if (index < 0)
		return ThrowNativeError(0, "Index '%d' is invalid.", index);

	int maxlen = GetNativeCell(5);

	char[] parameter = new char[maxlen];
	GetNativeString(4, parameter, maxlen);

	int len = GetOutputParameter(entity, output, index, parameter, maxlen);
	if (len)
		SetNativeString(4, parameter, maxlen);

	return len;
}

any Native_GetOutputDelay(Handle plugin, int params)
{
	int entity = GetNativeCell(1);
	if (!IsValidEntity(entity))
		return ThrowNativeError(0, "Entity '%d' is invalid.", entity);

	char output[256];
	GetNativeString(2, output, sizeof(output));

	int index = GetNativeCell(3);
	if (index < 0)
		return ThrowNativeError(0, "Index '%d' is invalid.", index);

	return GetOutputDelay(entity, output, index);
}

int Native_GetOutputRefires(Handle plugin, int params)
{
	int entity = GetNativeCell(1);
	if (!IsValidEntity(entity))
		return ThrowNativeError(0, "Entity '%d' is invalid.", entity);

	char output[256];
	GetNativeString(2, output, sizeof(output));

	int index = GetNativeCell(3);
	if (index < 0)
		return ThrowNativeError(0, "Index '%d' is invalid.", index);

	return GetOutputRefires(entity, output, index);
}

int Native_GetOutputValue(Handle plugin, int params)
{
	int entity = GetNativeCell(1);
	if (!IsValidEntity(entity))
		return ThrowNativeError(0, "Entity '%d' is invalid.", entity);

	char output[256];
	GetNativeString(2, output, sizeof(output));

	return GetOutputValue(entity, output);
}

any Native_GetOutputValueFloat(Handle plugin, int params)
{
	int entity = GetNativeCell(1);
	if (!IsValidEntity(entity))
		return ThrowNativeError(0, "Entity '%d' is invalid.", entity);

	char output[256];
	GetNativeString(2, output, sizeof(output));

	return GetOutputValueFloat(entity, output);
}

int Native_GetOutputValueString(Handle plugin, int params)
{
	int entity = GetNativeCell(1);
	if (!IsValidEntity(entity))
		return ThrowNativeError(0, "Entity '%d' is invalid.", entity);

	char output[256];
	GetNativeString(2, output, sizeof(output));

	int maxlen = GetNativeCell(4);

	char[] value = new char[maxlen];
	GetNativeString(3, value, maxlen);

	int len = GetOutputValueString(entity, output, value, maxlen);
	if (len)
		SetNativeString(3, value, maxlen);

	return len;
}

int Native_GetOutputValueVector(Handle plugin, int params)
{
	int entity = GetNativeCell(1);
	if (!IsValidEntity(entity))
		return ThrowNativeError(0, "Entity '%d' is invalid.", entity);

	char output[256];
	GetNativeString(2, output, sizeof(output));

	float value[3];
	GetNativeArray(3, value, sizeof(value));

	int res = view_as<int>(GetOutputValueFloat(entity, output, true, value));
	if (res)
		SetNativeArray(3, value, sizeof(value));

	return res;
}

int Native_FindOutput(Handle plugin, int params)
{
	int entity = GetNativeCell(1);
	if (!IsValidEntity(entity))
		return ThrowNativeError(0, "Entity '%d' is invalid.", entity);

	char output[256];
	GetNativeString(2, output, sizeof(output));

	int startIndex = GetNativeCell(3);
	if (startIndex < 0)
		return ThrowNativeError(0, "StartIndex '%d' is invalid.", startIndex);

	char target[256];
	GetNativeString(4, target, sizeof(target));

	char targetInput[256];
	GetNativeString(5, targetInput, sizeof(targetInput));

	char parameter[256];
	GetNativeString(6, parameter, sizeof(parameter));

	float delay = view_as<float>(GetNativeCell(7));
	int refires = GetNativeCell(8);

	return FindOutput(entity, output, startIndex, target, targetInput, parameter, delay, refires);
}

int Native_DeleteOutput(Handle plugin, int params)
{
	int entity = GetNativeCell(1);
	if (!IsValidEntity(entity))
		return ThrowNativeError(0, "Entity '%d' is invalid.", entity);

	char output[256];
	GetNativeString(2, output, sizeof(output));

	int index = GetNativeCell(3);

	return DeleteOutput(entity, output, index);
}

int Native_DeleteAllOutputs(Handle plugin, int params)
{
	int entity = GetNativeCell(1);
	if (!IsValidEntity(entity))
		return ThrowNativeError(0, "Entity '%d' is invalid.", entity);

	char output[256];
	GetNativeString(2, output, sizeof(output));

	return DeleteAllOutputs(entity, output);
}

int Native_GetOutputFormatted(Handle plugin, int params)
{
	int entity = GetNativeCell(1);
	if (!IsValidEntity(entity))
		return ThrowNativeError(0, "Entity '%d' is invalid.", entity);

	char output[256];
	GetNativeString(2, output, sizeof(output));

	int index = GetNativeCell(3);
	if (index < 0)
		return ThrowNativeError(0, "Index '%d' is invalid.", index);

	int maxlen = GetNativeCell(5);

	char[] formatted = new char[maxlen];
	GetNativeString(4, formatted, maxlen);

	int len = GetOutputFormatted(entity, output, index, formatted, maxlen);
	if (len)
		SetNativeString(4, formatted, maxlen);

	return len;
}

int Native_GetOutputNames(Handle plugin, int params)
{
	int entity = GetNativeCell(1);
	if (!IsValidEntity(entity))
		return ThrowNativeError(0, "Entity '%d' is invalid.", entity);

	int index = GetNativeCell(2);
	if (index < 0)
		return ThrowNativeError(0, "Index '%d' is invalid.", index);

	int maxlen = GetNativeCell(4);

	char[] output = new char[maxlen];
	GetNativeString(3, output, maxlen);

	int len = GetOutputNames(entity, index, output, maxlen);
	if (len)
		SetNativeString(3, output, maxlen);

	return len;
}

public void OnPluginStart()
{
	InitStructOffsets();

	GameData gd = new GameData("EntityOutputInfo.games");
	if (gd == null)
	{
		LogError("Could not find gamedata file, some features may be neglected!");
	}
	else
	{
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "CEventAction__operator_delete");
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer);

		g_hDeleteElement = EndPrepSDKCall();
		if (g_hDeleteElement == null)
		{
			LogError("Could not get a good SDKCall handle for CEventAction__operator_delete, DeleteOutput/DeleteAllOutputs will not work.");
		}

		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(gd, SDKConf_Virtual, "CBaseEntity_GetDataDescMap");
#if SOURCEMOD_V_MINOR >= 13
		// A pointer does not fit in a cell on x64: SM 1.13 returns it through an Address (int64) argument
		PrepSDKCall_SetReturnInfo(SDKType_Address, SDKPass_Plain);
#else
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
#endif
		g_hGetDataDescMap = EndPrepSDKCall();

		typedescription_t_size = gd.GetOffset("typedescription_t_size");

		if (g_hGetDataDescMap == null || typedescription_t_size == -1)
		{
			delete g_hGetDataDescMap;
			LogError("Could not get a good SDKCall handle for CBaseEntity_GetDataDescMap or the typedescription_t size, GetOutputNames will not work.");
		}

		delete gd;
	}
}

// 32-bit struct offsets, or the 64-bit ones (pointers and string_t are 8 bytes, aligned on 8)
void InitStructOffsets()
{
	// datamap_t
	dataNumFields_offset  = view_as<Address>(0x04);
	baseMap_offset        = view_as<Address>(0x0C);

	// typedescription_t
	fieldName_offset      = view_as<Address>(0x04);
	flags_offset          = view_as<Address>(0x12);

	// varianthax_t m_Value
	fieldType_var_offset  = view_as<Address>(0x10);

	// CBaseEntityOutput
	m_ActionList_offset   = view_as<Address>(0x14);

	// CEventAction (m_iIDStamp is at 0x14)
	m_iTargetInput_offset = view_as<Address>(0x04);
	m_iParameter_offset   = view_as<Address>(0x08);
	m_flDelay_offset      = view_as<Address>(0x0C);
	m_nTimesToFire_offset = view_as<Address>(0x10);
	m_pNext_offset        = view_as<Address>(0x18);

#if SOURCEMOD_V_MINOR >= 13
	if (Address_PointerSize != view_as<Address>(8))
		return;

	// datamap_t
	dataNumFields_offset  = view_as<Address>(0x08);
	baseMap_offset        = view_as<Address>(0x18);

	// typedescription_t
	fieldName_offset      = view_as<Address>(0x08);
	flags_offset          = view_as<Address>(0x1A);

	// varianthax_t m_Value
	fieldType_var_offset  = view_as<Address>(0x14);

	// CBaseEntityOutput
	m_ActionList_offset   = view_as<Address>(0x18);

	// CEventAction (m_iIDStamp is at 0x20)
	m_iTargetInput_offset = view_as<Address>(0x08);
	m_iParameter_offset   = view_as<Address>(0x10);
	m_flDelay_offset      = view_as<Address>(0x18);
	m_nTimesToFire_offset = view_as<Address>(0x1C);
	m_pNext_offset        = view_as<Address>(0x28);
#endif
}

// Reads a pointer-sized value (SM 1.12 only knows 32-bit pointers)
Address LoadPointer(Address addr)
{
#if SOURCEMOD_V_MINOR >= 13
	return LoadAddressFromAddress(addr);
#else
	return view_as<Address>(LoadFromAddress(addr, NumberType_Int32));
#endif
}

void StorePointer(Address addr, Address value)
{
#if SOURCEMOD_V_MINOR >= 13
	StoreAddressToAddress(addr, value);
#else
	StoreToAddress(addr, view_as<int>(value), NumberType_Int32);
#endif
}

Address GetDataDescMap(int entity)
{
#if SOURCEMOD_V_MINOR >= 13
	Address datamap = Address_Null;
	SDKCall(g_hGetDataDescMap, entity, datamap);
	return datamap;
#else
	return SDKCall(g_hGetDataDescMap, entity);
#endif
}

char[] GetEntityName(int entity)
{
	char name[64];
	GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
	if (name[0] == '\0')
		FormatEx(name, sizeof(name), "#%d", EntIndexToEntRef(entity));

	return name;
}

Address GetActionAtIndex(Address outputAddr, int index)
{
	Address actionList = GetOutputActionList(outputAddr);
	if (!actionList)
		return Address_Null;

	int count = 0;
	while (actionList)
	{
		if (count == index)
			return actionList;

		actionList = LoadPointer(actionList + m_pNext_offset);
		count++;
	}

	return Address_Null;
}

Address GetOutputAddress(int entity, const char[] output)
{
	int outputOffset = FindDataMapInfo(entity, output);
	if (outputOffset == -1)
		return view_as<Address>(0x0);

	Address outputAddr = GetEntityAddress(entity) + view_as<Address>(outputOffset);
	if (!outputAddr)
		return view_as<Address>(0x0);

	return outputAddr;
}

Address GetOutputActionList(Address outputAddr)
{
	return LoadPointer(outputAddr + m_ActionList_offset);
}

int GetOutputCount(int entity, const char[] output)
{
	Address outputAddr = GetOutputAddress(entity, output);
	if (!outputAddr)
		return 0;

	Address actionList = GetOutputActionList(outputAddr);
	if (!actionList)
		return 0;

	int count = 0;
	while (actionList)
	{
		actionList = LoadPointer(actionList + m_pNext_offset);
		count++;
	}

	return count;
}

int GetOutputTarget(int entity, const char[] output, int index, char[] target, int maxlen)
{
	Address outputAddr = GetOutputAddress(entity, output);
	if (!outputAddr)
		return 0;

	Address action = GetActionAtIndex(outputAddr, index);
	if (!action)
		return 0;

	Address m_iTarget = LoadPointer(action + m_iTarget_offset);
	return StringtToCharArray(m_iTarget, target, maxlen, true);
}

int GetOutputTargetInput(int entity, const char[] output, int index, char[] targetInput, int maxlen)
{
	Address outputAddr = GetOutputAddress(entity, output);
	if (!outputAddr)
		return 0;

	Address action = GetActionAtIndex(outputAddr, index);
	if (!action)
		return 0;

	Address m_iTargetInput = LoadPointer(action + m_iTargetInput_offset);
	return StringtToCharArray(m_iTargetInput, targetInput, maxlen, true);
}

int GetOutputParameter(int entity, const char[] output, int index, char[] parameter, int maxlen)
{
	Address outputAddr = GetOutputAddress(entity, output);
	if (!outputAddr)
		return 0;

	Address action = GetActionAtIndex(outputAddr, index);
	if (!action)
		return 0;

	Address m_iParameter = LoadPointer(action + m_iParameter_offset);
	return StringtToCharArray(m_iParameter, parameter, maxlen, true);
}

float GetOutputDelay(int entity, const char[] output, int index)
{
	Address outputAddr = GetOutputAddress(entity, output);
	if (!outputAddr)
		return -1.0;

	Address action = GetActionAtIndex(outputAddr, index);
	if (!action)
		return -1.0;

	return view_as<float>(LoadFromAddress(action + m_flDelay_offset, NumberType_Int32));
}

int GetOutputRefires(int entity, const char[] output, int index)
{
	Address outputAddr = GetOutputAddress(entity, output);
	if (!outputAddr)
		return 0;

	Address action = GetActionAtIndex(outputAddr, index);
	if (!action)
		return 0;

	return LoadFromAddress(action + m_nTimesToFire_offset, NumberType_Int32);
}

int GetOutputValue(int entity, const char[] output)
{
	Address outputAddr = GetOutputAddress(entity, output);
	if (!outputAddr)
		return 0;

	int fieldType = LoadFromAddress(outputAddr + fieldType_var_offset, NumberType_Int32);
	switch (fieldType)
	{
		case FIELD_TICK, FIELD_MODELINDEX, FIELD_MATERIALINDEX, FIELD_INTEGER, FIELD_COLOR32, FIELD_SHORT, FIELD_CHARACTER, FIELD_BOOLEAN:
		{
			return LoadFromAddress(outputAddr + Union_Val_offset, NumberType_Int32);
		}
	}

	ThrowError("Entity '%s': %s value is not an integer (%d)", GetEntityName(entity), output, fieldType);
	return 0;
}

float GetOutputValueFloat(int entity, const char[] output, bool isVector = false, float vec[3] = {0.0, 0.0, 0.0})
{
	Address outputAddr = GetOutputAddress(entity, output);
	if (!outputAddr)
		return 0.0;

	int fieldType = LoadFromAddress(outputAddr + fieldType_var_offset, NumberType_Int32);
	switch (fieldType)
	{
		case FIELD_FLOAT, FIELD_TIME:
		{
			if (!isVector)
			{
				return view_as<float>(LoadFromAddress(outputAddr + Union_Val_offset, NumberType_Int32));
			}
			else
			{
				Address baseAddr = outputAddr + Union_Val_offset;
				vec[0] = view_as<float>(LoadFromAddress(baseAddr + view_as<Address>(0x0), NumberType_Int32));
				vec[1] = view_as<float>(LoadFromAddress(baseAddr + view_as<Address>(0x4), NumberType_Int32));
				vec[2] = view_as<float>(LoadFromAddress(baseAddr + view_as<Address>(0x8), NumberType_Int32));
				return 1.0;
			}
		}
	}

	ThrowError("Entity '%s': %s value is not a float (%d)", GetEntityName(entity), output, fieldType);
	return 0.0;
}

int GetOutputValueString(int entity, const char[] output, char[] value, int maxlen)
{
	Address outputAddr = GetOutputAddress(entity, output);
	if (!outputAddr)
		return 0;

	int fieldType = LoadFromAddress(outputAddr + fieldType_var_offset, NumberType_Int32);
	switch (fieldType)
	{
		case FIELD_CHARACTER, FIELD_STRING, FIELD_MODELNAME, FIELD_SOUNDNAME:
		{
			Address unionVal = LoadPointer(outputAddr + Union_Val_offset);
			return StringtToCharArray(unionVal, value, maxlen, true);
		}
	}

	ThrowError("Entity '%s': %s value is not a string (%d)", GetEntityName(entity), output, fieldType);
	return 0;
}

int FindOutput(int entity, const char[] output, int startIndex, const char[] target = "", const char[] targetInput = "", const char[] parameter = "", float delay = -1.0, int timesToFire = 0)
{
	Address outputAddr = GetOutputAddress(entity, output);
	if (!outputAddr)
		return -1;

	Address actionList = GetOutputActionList(outputAddr);
	if (!actionList)
		return -1;

	int count = 0;
	while (actionList)
	{
		count++;
		if (startIndex > 0)
		{
			startIndex--;
			continue;
		}

		Address oldActionList = actionList;
		actionList = LoadPointer(actionList + m_pNext_offset);

		if (target[0])
		{
			Address m_iTarget = LoadPointer(oldActionList + m_iTarget_offset);

			char thisTarget[64];
			StringtToCharArray(m_iTarget, thisTarget, sizeof(thisTarget), true);

			if (strcmp(target, thisTarget) != 0)
				continue;
		}

		if (targetInput[0])
		{
			Address m_iTargetInput = LoadPointer(oldActionList + m_iTargetInput_offset);

			char thisTargetInput[64];
			StringtToCharArray(m_iTargetInput, thisTargetInput, sizeof(thisTargetInput), true);

			if (strcmp(targetInput, thisTargetInput) != 0)
				continue;
		}

		if (parameter[0])
		{
			Address m_iParameter = LoadPointer(oldActionList + m_iParameter_offset);

			char thisParameter[256];
			StringtToCharArray(m_iParameter, thisParameter, sizeof(thisParameter), true);

			if (strcmp(parameter, thisParameter) != 0)
				continue;
		}

		if (delay != -1.0)
		{
			Address m_flDelay = oldActionList + m_flDelay_offset;

			float thisDelay = LoadFromAddress(m_flDelay, NumberType_Int32);
			if (delay != thisDelay)
				continue;
		}

		if (timesToFire != 0)
		{
			Address m_nTimesToFire = oldActionList + m_nTimesToFire_offset;

			int thisTimesToFire = LoadFromAddress(m_nTimesToFire, NumberType_Int32);
			if (timesToFire != thisTimesToFire)
				continue;
		}

		return count - 1;
	}

	return -1;
}

bool DeleteOutput(int entity, const char[] output, int index)
{
	if (g_hDeleteElement == null)
	{
		ThrowError("Invalid SDKCall Handle, cannot delete event actions");
	}

	Address outputAddr = GetOutputAddress(entity, output);
	if (!outputAddr)
		return false;

	Address actionList = GetOutputActionList(outputAddr);
	if (!actionList)
		return false;

	Address prevEvent = Address_Null;
	Address curEvent = Address_Null;
	int count = 0;
	while (actionList)
	{
		if (count == index)
		{
			curEvent = actionList;
			break;
		}

		prevEvent = actionList;
		actionList = LoadPointer(prevEvent + m_pNext_offset);
		count++;
	}

	if (curEvent == Address_Null)
		return false;

	if (prevEvent != Address_Null)
		StorePointer(prevEvent + m_pNext_offset, LoadPointer(curEvent + m_pNext_offset));
	else
		StorePointer(outputAddr + m_ActionList_offset, LoadPointer(curEvent + m_pNext_offset));

	SDKCall(g_hDeleteElement, curEvent, curEvent);
	return true;
}

int DeleteAllOutputs(int entity, const char[] output)
{
	if (g_hDeleteElement == null)
	{
		ThrowError("Invalid SDKCall Handle, cannot delete event actions");
		return 0;
	}

	Address outputAddr = GetOutputAddress(entity, output);
	if (!outputAddr)
		return 0;

	Address actionList = GetOutputActionList(outputAddr);
	if (!actionList)
		return 0;

	int count = 0;
	Address nextEvent = actionList;
	StorePointer(outputAddr + m_ActionList_offset, Address_Null);

	while (nextEvent)
	{
		Address thisEvent = nextEvent;
		nextEvent = LoadPointer(nextEvent + m_pNext_offset);
		SDKCall(g_hDeleteElement, thisEvent, thisEvent);
		count++;
	}

	return count;
}

int GetOutputFormatted(int entity, const char[] output, int index, char[] formatted, int maxlen)
{
	Address outputAddr = GetOutputAddress(entity, output);
	if (!outputAddr)
		return 0;

	Address action = GetActionAtIndex(outputAddr, index);
	if (!action)
		return 0;

	Address m_iTarget = LoadPointer(action + m_iTarget_offset);
	char thisTarget[64];
	StringtToCharArray(m_iTarget, thisTarget, sizeof(thisTarget), true);

	Address m_iTargetInput = LoadPointer(action + m_iTargetInput_offset);
	char thisTargetInput[64];
	StringtToCharArray(m_iTargetInput, thisTargetInput, sizeof(thisTargetInput), true);

	Address m_iParameter = LoadPointer(action + m_iParameter_offset);
	char thisParameter[256];
	StringtToCharArray(m_iParameter, thisParameter, sizeof(thisParameter), true);

	float thisDelay = view_as<float>(LoadFromAddress(action + m_flDelay_offset, NumberType_Int32));
	int thisTimesToFire = LoadFromAddress(action + m_nTimesToFire_offset, NumberType_Int32);

	return FormatEx(formatted, maxlen, "%s,%s,%s,%f,%d",
		thisTarget, thisTargetInput, thisParameter, thisDelay, thisTimesToFire);
}

int GetOutputNames(int entity, int index, char[] output, int maxlen)
{
	if (g_hGetDataDescMap == null)
		ThrowError("Invalid SDKCall Handle, cannot get output names");

	Address datamap_t = GetDataDescMap(entity);
	if (!datamap_t)
		return 0;

	for (int count = 0; datamap_t; datamap_t = LoadPointer(datamap_t + baseMap_offset))
	{
		Address dataDesc = LoadPointer(datamap_t + dataDesc_offset);
		int dataNumFields = LoadFromAddress(datamap_t + dataNumFields_offset, NumberType_Int32);
		for (int i = 0; i < dataNumFields; i++)
		{
			Address typedescription_t = dataDesc + view_as<Address>(i * typedescription_t_size);

			int fieldType = LoadFromAddress(typedescription_t + fieldType_offset, NumberType_Int32);
			if (fieldType != FIELD_CUSTOM)
				continue;

			int flags = LoadFromAddress(typedescription_t + flags_offset, NumberType_Int16);
			if (!(flags & FTYPEDESC_OUTPUT))
				continue;

			if (index == count)
			{
				Address fieldNameAddr = LoadPointer(typedescription_t + fieldName_offset);
				return StringtToCharArray(fieldNameAddr, output, maxlen, true);
			}

			count++;
		}
	}

	return 0;
}

int StringtToCharArray(Address addr, char[] buffer, int maxlen, bool allowNull = false)
{
	if (addr == Address_Null)
	{
		if (!allowNull)
		{
			ThrowError("string_t address is null");
		}
		else
		{
			buffer[0] = '\0';
			return 0;
		}
	}

	if (maxlen <= 0)
		ThrowError("Buffer size is negative or zero");

	int max = maxlen-1;
	int i = 0;
	while (i < max)
	{
		char c = view_as<char>(LoadFromAddress(addr + view_as<Address>(i), NumberType_Int8));
		if (c == '\0')
			break;

		buffer[i++] = c;
	}

	buffer[i] = '\0';
	return i;
}
