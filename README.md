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

<p>A traditional approach would be to write a series of packages containing types derived from <i>Greeter</i> and link them together statically or dynamically.</p>
<p>Now what if the designer of the application does not know anything of <i>Norddeutschland_Greeter</i> in adavance. Moreover what if we want to deploy the application and add it later or never? This is where plug-ins come in question. The package implementing <i>Norddeutschland_Greeter</i> is placed in a dynamically linked library which is loaded on demand.</p>
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
<p>Here we added a constructing function <i>Create</i> that takes the plug-in name as the argument and returns the object derived from <i>Greeter</i>. The rest are things for the plug-in implementation. The name of the library entry point to initialize the library and the contructing function that actually does the job.</p>
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

```
with "plugin_api.gpr";
project Plugin_Test is
   for Main         use ("plugin_test.adb");
   for Source_Files use ("plugin_test.adb");
   for Object_Dir   use "obj";
   for Exec_Dir     use "bin";
end Plugin_Test;
```
<p>The plug-in implementation is encapsulated into a library</p>

```Ada
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
```
<p>The package body:</p>

```Ada
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
```
<p>The implementation is self-explanatory yet there are some less trivial parts. First the library is initialized manually. It is necessary because if the library would use tasking automatic initialization might dead-lock. Here I show how to deal with manually initialized library. The project file is:</p>

```
with "plugin_api.gpr";
library project Plugin_Norddeutschland_Build is

   for Library_Name      use "plugin_norddeutschland";
   for Library_Kind      use "dynamic";
   for Object_Dir        use "obj";
   for Library_Dir       use "bin";
   for Source_Files      use ("plugin_norddeutschland.ads", "plugin_norddeutschland.adb");
   for Library_Auto_Init use "False";
   for Library_Interface use ("Plugin_Norddeutschland");
end Plugin_Norddeutschland_Build;
```
<p>Take note of <i>Library_Auto_Init</i> and <i>Library_Interface</i>. The later specifies the Ada package exposed by the library. <i>Init</i> from the package is the function called after the library is loaded. It checks if the library was already initialized and if not, it calls the library initialization code. The code is exposed by the builder as a C function with the name &lt;library-name&gt;init. Once initialized it returns the constructing function back.</p>
<p>On the plug-in API side we have:</p>

```Ada
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
```
<p>Ada.Containers.Indefinite_Ordered_Maps is used to create a map (<i>Loaded</i>) name to constructing function. When not in the map it tries to load the library. The function Load is placed into a separate body to be able to have implementation dependant on the operating system. I provide here Windows and Linux implementations. The plug-in project file used to build the API library has the scenario variable Target_OS to select the OS:</p>

```
library project Plugin_API_Build is
   type OS_Type is ("Windows", "Linux");
   Target_OS : OS_Type := external ("Target_OS", "Windows");

   for Library_Name use "plugin_api";
   for Library_Kind use "dynamic";
   for Object_Dir   use "obj";
   for Library_Dir  use "bin";
   for Source_Files use ("plugin_api.ads", "plugin_api.adb", "plugin_api-load.adb");
   case Target_OS is
      when "Windows" =>
         for Source_Dirs use (".", "windows");
      when "Linux" =>
         for Source_Dirs use (".", "linux");
   end case;
end Plugin_API_Build;
```
<p>Finally, here is a sequence of building everything togeter (for Linux):<p>

```
gprbuild -XTarget_OS=Linux plugin_api_build.gpr
gprbuild -XTarget_OS=Linux plugin_test.gpr
gprbuild -XTarget_OS=Linux plugin_norddeutschland_build.gpr
```
<p>Now go to the <i>bin</i> subdirectory and run the test:</p>

```
cd bin
./plugin_test

```
<p>You will see:</p>

```
Norddeutschland says Moin!
```
That is all.
