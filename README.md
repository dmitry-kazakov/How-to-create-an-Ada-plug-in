<H1>Ada plug-in</H1>
<p>Ada is a statically typed language. Does that mean an Ada application must include everything in advance? Not at all. Ada tagged types provide an excellent support of late bindings. Here I show how to write dynamically linked plug-ins in Ada.</p>
The task is this. Let us have some base tagged type, possibly abstract.

```Ada
--
-- This type represents greetings used in different countries and regions.
--
   type Greeter is abstract tagged null record;
--
-- The operation that returns the greeting
--
   function Greet (Object : Greeter) return String is abstract;
```
<p>An application should be able to create instances of types <i>derived</i> from the base.</p>

```Ada
   type Norddeutschland_Greeter is
      new PlugIn_API.Greeter with null record;
   overriding
      function Greet (Object : Norddeutschland_Greeter) return String is
         ("Moin!");
```

<p>A monolithic approach would be to write a series of packages containing types derived from <i>Greeter</i>.</p>
<p>Now what if the designer of the application does not know of <i>Norddeutschland_Greeter</i> in adavance. Moreover what if we want to deploy the application and add it later or never? This is where plug-ins come in question. The package implementing <i>Norddeutschland_Greeter</i> is placed in a dynamically linked library which is loaded on demand</p>
<p>The interface of the plug-in package is this</p>

```Ada
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
```
<p>Here we added a constructing function Create that takes the plug-in name as the argument and returns the object derived from <i>Greeter</i>. The rest are things for the plug-in implementation. The name of the library entry point to initialize the library and the contructing function that actually does the job.</p>
<p>Now the application is as simple as this</p>

```Ada
with Ada.Text_IO;  use Ada.Text_IO;
with PlugIn_API;   use PlugIn_API;

procedure Plugin_Test is
   Hello : constant Greeter'Class := Create ("norddeutschland");
begin
   Put_Line ("Norddeutschland says " & Hello.Greet);
end Plugin_Test;
```
<p>Note that it knows nothing about the implementation, just the name of, The project file too refers only to the plug-in interface:</p>
<tt>
with "plugin_api.gpr";

project Plugin_Test is

   for Main         use ("plugin_test.adb");
   for Source_Files use ("plugin_test.adb");
   for Object_Dir   use "obj";
   for Exec_Dir     use "bin";

end Plugin_Test;  
</tt>
