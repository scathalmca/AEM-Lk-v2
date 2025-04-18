function [Resonance, Q_Factor] = Auto_Sim(Project, upperbound, lowerbound)
%  AUTO_SIM2 Brief summary of this function.
%
% Detailed explanation of this function.
% Add to the simulation counter
SimCounter("sim");
% Check is a .csv file already exists with the same project filename and
% remove.
csv_name=erase(Project.Filename(), ".son") + ".csv";
if isfile(csv_name)
    delete(csv_name);
end

% Clean the project file.
try
    Project.cleanProject;
catch
end
% Delete all existing File-Output and Frequency Sweeps/
delFileOutput(Project);
delFreqSweeps(Project);
% Add the given frequency sweep range with 2,000 points.
Project.addAbsEntryFrequencySweep(lowerbound, upperbound, 2000);
% Add a file output to the project folder with the starting geometry file
% name.csv
Project.addFileOutput("CSV","D","Y","$BASENAME.csv","NC","Y","S","MA","R",50);
Project.save;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       Calling CMD Line to simulate Project
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Sonnet path
Path = SonnetPath();

% If the folder for simulation results doesn't exist create it
[path, name] = fileparts(Project.Filename);
path=strrep(path,'\',filesep);
path=strrep(path,'/',filesep);
if isempty(path)
    path='.';
end

aFolderLocation=[path filesep 'sondata' filesep strrep(name,'.son','')];

[~,result]=mkdir(aFolderLocation);

% Simulation log file
aLogFilename=[aFolderLocation filesep 'SimulationStatus.log'];

% Call to unlock the project file.
aCallToSystem=['"' Path filesep 'bin' filesep 'soncmd.exe" -unlock "' Project.Filename '"'];

[aStatus, aMessage]=system(aCallToSystem);

% cmd to simulate the project with emstatus.exe, produce a log file to
% monitor the simulation, and finally close Sonnet when the simulation is
% complete.
aCallToSystem=['"' Path filesep 'bin' filesep 'emstatus.exe" -Run "' Project.Filename '" -LogFile "' aLogFilename '" -CloseWhenDone &'];

% Call cmd line to simulate the project
[aStatus, aMessage]=system(aCallToSystem);

pause(0.5);

%Kill any cmd display windows
[~,~]=system("taskkill /F /IM cmd.exe");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% In order to extract data from Sonnet, we produce a .csv file. Before
% that, we need to monitor the existance of the file.

csv_startTime = tic;

while true
    %If .csv exists, break while statement

    % Normally, a while loop would be sufficient, but tests show that we
    % need to put a timer on the existance of the file. Same for the Log
    % file.
    csv_elapsedTime = toc(csv_startTime);

    % If the csv file exists, break from the while loop
    if isfile(csv_name)
        disp("CSV File found")

        break

        % If the creation of the csv file takes longer than 30 seconds, re-run
        % the simulation
    elseif csv_elapsedTime > 30

        % close sonnet
        [~,~]=system("taskkill /F /IM sonnet.exe");

        [Resonance, Q_Factor] = Auto_Sim(Project, upperbound, lowerbound);

        return


    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% When the project has finished simulating, Sonnet will close and we can
% extract data.
while true
    
    % Check what programs are currently running
    [~,b] = system('tasklist');

    % Check if sonnet is running
    Sonnet_Status = contains(b, 'sonnet.exe');

    % If Sonnet is not running, this means that the simulation has
    % completed
    if Sonnet_Status == 0
        try
            % Extract resonant frqeuency and Qc Factor
            [Resonance, Q_Factor] = Auto_Extract(Project)
        catch ME
            % Some error occurred, so repeat Auto_Sim
            [Resonance, Q_Factor] = Auto_Sim(Project, upperbound+0.5, lowerbound-0.5);
        end
        return
    end

end

end
