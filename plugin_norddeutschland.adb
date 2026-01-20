package body Plugin_Norddeutschland is

   Initialized : Boolean := False;

   function Constructor return PlugIn_API.Greeter'Class is
   begin
      return Norddeutschland_Greeter'(PlugIn_API.Greeter with null record);
   end Constructor;

   function Init return PlugIn_API.Factory is
      procedure Do_Init;
      pragma Import (C, Do_Init, "plugin_norddeutschlandinit");
   begin
      if not Initialized then -- Initialize library
         Initialized := True;
         Do_Init;
      end if;
      return Constructor'Access;
   end Init;

end Plugin_Norddeutschland;
