with Ada.Text_IO;  use Ada.Text_IO;
with PlugIn_API;   use PlugIn_API;

procedure Plugin_Test is
   Hello : constant Greeter'Class := Create ("norddeutschland");
begin
   Put_Line ("Norddeutschland says " & Hello.Greet);
end Plugin_Test;
