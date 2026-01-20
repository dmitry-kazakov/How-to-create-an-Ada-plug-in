with Interfaces.C;          use Interfaces.C;
with Interfaces.C.Strings;  use Interfaces.C.Strings;
with System;                use System;

separate (Plugin_API)
   function Load (Library_File : String) return Factory is
   function dlopen (filename : char_array; flag : int := 1)
      return Address;
   pragma Import (C, dlopen);
   function dlsym (handle : Address;  symbol : char_array)
      return PlugIn_Entry_Ptr;
   pragma Import (C, dlsym);

   function Error_Text return String is
      function dlerror return chars_ptr;
      pragma Import (C, dlerror);
      Ptr : constant chars_ptr := dlerror;
   begin
      if Ptr = Null_Ptr then
         return "";
      else
         return Value (Ptr);
      end if;
   end Error_Text;

   File_Name : char_array := To_C ("libplugin_" & Library_File & ".so");
   Library   : Address;
   Entry_Ptr : PlugIn_Entry_Ptr;
begin
   Library := dlopen (File_Name);
   if Library = Null_Address then
      raise PlugIn_Error with "Unable to load " & To_Ada (File_Name) & ": " & Error_Text;
   end if;
   Entry_Ptr := dlsym (Library, To_C (PlugIn_Entry_Name));
   if Entry_Ptr = null then
      raise PlugIn_Error with "Unable to find entry " &
            PlugIn_Entry_Name                         &
            " in "                                    &
            To_Ada (File_Name);
   end if;
   return Entry_Ptr.all;
end Load;
