package Plugin_API is

   PlugIn_Error : exception;
--
-- The greeter abstract  base to  be extended by the plug-ins.  The type
-- represents greetings used in different countries and regions.
--
   type Greeter is abstract tagged null record;
--
-- The operation that returns the greeting
--
   function Greet (Object : Greeter) return String is abstract;
--
-- This creates  a greeting object using  Name for  the region name.  It
-- loads the corresponding plug-in if necessary.
--
   function Create (Name : String) return Greeter'Class;
------------------------------------------------------------------------
--
-- The function of the plug-in that creates an instance
--
   type Factory is access function return Greeter'Class;
--
-- The name of the plug-in entry point to call once after loading
--
   PlugIn_Entry_Name : constant String := "plugin_init";
--
-- The type of the entry point
--
   type PlugIn_Entry_Ptr is access function return Factory
      with Convention => C;

end Plugin_API;
