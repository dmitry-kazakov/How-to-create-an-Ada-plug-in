with Interfaces.C;  use Interfaces.C;
with System;        use System;

separate (Plugin_API)
   function Load (Library_File : String) return Factory is
   type HANDLE is new Interfaces.C.ptrdiff_t;
   INVALID_HANDLE_VALUE : constant HANDLE := -1;

   function LoadLibrary (lpFileName : char_array) return HANDLE;
   function GetProcAddress (hModule : HANDLE; Name : char_array)
      return PlugIn_Entry_Ptr;
   pragma Import (stdcall, LoadLibrary, "LoadLibrary", "LoadLibraryA");
   pragma Import (stdcall, GetProcAddress, "GetProcAddress");

   File_Name : char_array := To_C ("libplugin_" & Library_File & ".dll");
   Library   : HANDLE := INVALID_HANDLE_VALUE;
   Entry_Ptr : PlugIn_Entry_Ptr;
begin
   Library := LoadLibrary (File_Name);
   if Library = 0 then
      raise PlugIn_Error with "Unable to load " & To_Ada (File_Name);
   end if;
   Entry_Ptr := GetProcAddress (Library, To_C (PlugIn_Entry_Name));
   if Entry_Ptr = null then
      raise PlugIn_Error with "Unable to find entry " &
            PlugIn_Entry_Name                       &
            " in "                                  &
            To_Ada (File_Name);
   end if;
   return Entry_Ptr.all;
end Load;
