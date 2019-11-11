#/bin/bash
echo "Pls enter your libname:"
read libname

mkdir ${libname}
cd ${libname}
mkdir ${libname}_fuzz
mkdir ${libname}_fuzz/tests
mkdir ${libname}_fuzz/findings
mkdir ${libname}_repro
mkdir ${libname}_repro/crashes
echo "[+] Created Directories"

cd ${libname}_fuzz
wget https://www.nuget.org/api/v2/package/${libname}/
unzip * -d extlib/
echo "[+] Downloaded Library"
sharpfuzz extlib/lib/netstandard2*/*${libname}*.dll
echo "[+] Instrumented Library"
cp extlib/lib/netstandard2*/*${libname}*.dll .
dotnet new console
echo "[+] Created Project"

sed -i '$ d' ${libname}_fuzz.csproj

read -d '' items << EOF 
<ItemGroup> 
  <Reference Include="${libname}">
    <HintPath>${libname}.dll</HintPath>
  </Reference>
</ItemGroup>
</Project>
EOF

echo "${items}" >> ${libname}_fuzz.csproj
echo "[+] Updated Project files"

read -d '' boilerplate_fuzz << EOF
using System;
using System.IO;
using SharpFuzz;
#Add dependency here

namespace ${libname}_fuzz
{
  public class Program
  {
    public static void Main(string[] args)
    {
      Fuzzer.Run(stream =>
      {
	/*
        try
        {
          using (var reader = new StreamReader(stream))
          {
          }
        }
        catch (DefaultException) { }
	*/
      });
    }
  }
}
EOF
echo "${boilerplate_fuzz}" > Program.cs
echo "[+] Updated Fuzzing Harness"


echo "[!] Moving to reproduction generation"
echo "[!] Once finished fuzzing please copy crashes to ${libname}_repro/crashes"

cd ../${libname}_repro
dotnet new console
dotnet add package ${libname}
read -d '' boilerplate_repro << EOF
using System;
using System.IO;
#Add dependency here

namespace ${libname}_repro
{
    class Program
    {
        static void Main(string[] args)
        {
        	string[] files = Directory.GetFiles("crashes", "*.*", SearchOption.AllDirectories);

        	foreach ( string filename in files)
            	{
                	try{
                        	Stream stream = new FileStream(filename, FileMode.Open);
				/*
                        	using (var zipInputStream = new ZipInputStream(stream))
				{
                        		while (zipInputStream.GetNextEntry() is ZipEntry ze)
					{
                                		Console.WriteLine(ze.Name);
                        		}
                		}
				*/
                	} catch(Exception e)
			{
                        	Console.WriteLine(e);
                	}
             	}
        }
    }
}
EOF
echo "${boilerplate_repro}" > Program.cs
echo "[+] Updated Reproduction Program"
