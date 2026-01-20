with Ada.Containers.Indefinite_Ordered_Maps;

package body Plugin_API is
--
-- Map plugin name -> factory function
--
   package Plugin_Maps is
      new Ada.Containers.Indefinite_Ordered_Maps (String, Factory);

   Loaded : Plugin_Maps.Map;

   function Load (Library_File : String) return Factory is separate;

   function Create (Name : String) return Greeter'Class is
   begin
      if not Loaded.Contains (Name) then
         Loaded.Insert (Name, Load (Name));
      end if;
      return Loaded.Element (Name).all;
   end Create;

end Plugin_API;
