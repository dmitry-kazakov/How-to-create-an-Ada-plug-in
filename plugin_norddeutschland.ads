with PlugIn_API;

package Plugin_Norddeutschland is

   type Norddeutschland_Greeter is
      new PlugIn_API.Greeter with null record;
   overriding
      function Greet (Object : Norddeutschland_Greeter) return String is
         ("Moin!");

private
   function Init return PlugIn_API.Factory with
      Export => True, External_Name => "plugin_init";

end Plugin_Norddeutschland;
