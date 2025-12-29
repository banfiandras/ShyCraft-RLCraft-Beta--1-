=========================

Please set the following in your server.properties files when it generates, for stability and compatibility:

allow-flight=true
difficulty=3
max-tick-time=-1
enable-command-block=true

=========================

allow-flight: needs to be true for things like mounts that fly and fairy ring, or the server will kick players using those.

difficulty: needs to be 3 for hard difficulty mode and the difficulty RLCraft is balanced around.

max-tick-time: need to be -1 for big structures that generate (AND FOR PREGENNING AS WELL) as these structures take take some time to generate, and this prevents forge from thinking the server crashed and auto shutting it down.

enable-command-block: MUST be TRUE for villagers to spawn correctly in generated structures.

=========================

YOU SHOULD PREGEN YOUR WORLD IF YOU PLAN TO RUN A SERVER WITH MULTIPLE PLAYERS:

How to Pre-generate a 10k block radius (Square) world:

Download: https://www.curseforge.com/minecraft/mc-mods/chunkpregenerator/files/3946413
Place that jar in your mods folder (Server mods folder if a server) and verify the chunkpregenerator version is 2.5.7

Run these commands (In console if a server, in game if singleplayer):

/pregen utils setPriority pregenerator
/pregen timepertick 250
/pregen gen startradius square 0 0 b10000

Optionally you can also add a worldborder to prevent people from generating additional chunks and still lagging the server with the following command:
Note: works in diameter so 10000 in all directions from the center makes for 20000.

/worldborder set 20000

Once finished generating, restart your game or server and remove the pregenerator mod.

You can additionally use this command, to pause pregen automatically when players are online, if you'd like to keep your server active with constant pregen, without interrupting players.

/pregen utils setPlayerLimit 1

=========================
Quick Windows Server Install Guide (Or just google it 5head)

1. Move this extracted server pack folder to where you want your server to be installed
2. Download the Forge 2860 server installer: https://maven.minecraftforge.net/net/minecraftforge/forge/1.12.2-14.23.5.2860/forge-1.12.2-14.23.5.2860-installer.jar
3. Double click to run the installer, select "Install Server" and select this directory to install the server here, then run it and wait for it to finish
4. Create a new text file in the same directory, edit it, and paste the below line, this will set the launch args for your server:

java -server -Xmx6G -Xms6G -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=50 -XX:G1NewSizePercent=20 -XX:G1ReservePercent=20  -XX:G1HeapRegionSize=32M -jar forge-1.12.2-14.23.5.2860.jar nogui

(Change the number next to -Xmx and -Xms to increase or decrease allocated RAM)
5. Save the text file, then rename it run.bat (Note: run.bat, not run.bat.txt)
6. Double click the run.bat file to run it, the server will start and then stop with a message that you need to agree to the EULA in the server.properties
(If it instead crashes, you likely do not have Java 8 installed and need to download and install the Java 8 JDK from a site like Adoptium)
7. Close the server window, edit the server.properties file to agree to the EULA, and read the rest of this file and modify the server.properties accordingly
8. After editing the file, save and close it, then run the run.bat file again to launch your server

=========================

IF USING SPONGEFORGE:  You must disable "Entity Tracker Desync" and "Outdated Chunk Data" in the rlmixins.cfg, as SpongeForge already implements the same/similar patches and will crash.

NOTE: As we do not use SpongeForge on the official servers, there may be other issues or crashes unaccounted for in this readme, our official discord will have the most up to date information

=========================