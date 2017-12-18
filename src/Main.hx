package;

import arguable.ArgParser;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

/**
 * ...
 * @author grosmar
 */
class Main 
{
	var buildFile:String;
	
	static function main() 
	{
		new Main();
	}
	
	public function new()
	{
		var args = ArgParser.parse(Sys.args());
		
		if ( args.has("help") )
		{
			showHelp();
			Sys.exit(0);
		}
		
		if ( args.has("dir") )
			Sys.setCwd(args.get("dir").value);

		var outputFile = args.has("out") ? args.get("out").value : "completion.hxml";
		
			
		buildFile = args.has("build") ? args.get("build").value : findFirstBuildFile();
		
		var lib = getLibraries();

		File.saveContent(outputFile, lib);

		
	}
	
	function showHelp() 
	{
		Sys.println("Usage: intellij-lix-gen [arguments]");
		Sys.println("--dir <WorkingDirectory>   Directory it should run in. By default, ");
		Sys.println("                           it will take the current working directiory");
		Sys.println("--out <outputFile>         Destination htxl file where to save dependencies");
		Sys.println("--build <BuildFile>        hxml build file that represents all the library dependencies.");
		Sys.println("                           By default it searches for build.hxml or the first available hxml");
		Sys.println("--help                     Shows this command");
	}
	
	function findFirstBuildFile() 
	{
		if ( FileSystem.exists("build.hxml") && !FileSystem.isDirectory("build.hxml")  )
		{
			Sys.println("Default build file will be used: build.hxml");
			return "build.hxml";
		}
		
		var buildFiles = FileSystem.readDirectory("./").filter( function (file:String) return Path.extension(file) == "hxml" );
		
		if ( buildFiles.length == 0 )
		{
			Sys.println("Not found default build file. Please provide one");
			Sys.exit(1);
			return null;
		}
		
		Sys.println("Default build file will be used: " + buildFiles[0]);
		
		return buildFiles[0];
	}
	
	function getLibraries()
	{
		var out = readDependencies();
		
		var rDep = ~/(-?-[a-zA-Z0-9_]+)\n/g;
		
		out = rDep.replace(out, "$1 ");

		var result = out.split("\n");

		result.sort( function(a,b) return a < b ? -1 : 1);

		out = result.join("\n");
		
		return out;
	}
	
	function readDependencies():String
	{
		var folder = "./haxe_libraries";
		if ( !FileSystem.exists(folder) || !FileSystem.isDirectory(folder) )
		{
			Sys.println("No 'haxe_libraries' folder found. Run the application in the root folder of lix dependencies");
			Sys.exit(1);
			return null;
		}
		
		var p = new Process("haxe --run resolve-args " + buildFile);
		
		var bytes = p.stdout.readAll();
		return bytes.getString(0, bytes.length);
	}

	function getMatches(ereg:EReg, input:String, index:Int = 0):Array<String> 
	{
		var matches = [];
		while (ereg.match(input)) 
		{
			matches.push(ereg.matched(index)); 
			input = ereg.matchedRight();
		}
		return matches;
	}

	
}