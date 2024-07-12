function [Resonance, Q_Factor] = Auto_Sim(Project, upperbound, lowerbound)
%  AUTO_SIM2 Brief summary of this function.
% 
% Detailed explanation of this function.
global Time_Limit FirstLogProject
% Add to the simulation counter
SimCounter("sim");
% Check is a .csv file already exists with the same project filename and
% remove.
csv_name=erase(Project.Filename(), ".son") + ".csv";
if isfile(csv_name)
    delete(csv_name);
end
[filepath, ~] = fileparts(Project.Filename);
filepath=strrep(filepath,'\',filesep);
filepath=strrep(filepath,'/',filesep);
if isempty(filepath)
    filepath='.';
end
aFolderLocation=[filepath filesep 'sondata' filesep strrep(Project.Filename,'.son','')];
if isfile(aFolderLocation)
    rmdir(aFolderLocation, 's');
end
if contains(FirstLogProject, 'Empty')
    FirstLogProject = sprintf('%s', strrep(Project.Filename,'.son',''));
else
    FirstLogProject = sprintf('%s', strrep(FirstLogProject,'.son',''));
end
aSimlogfile_path = [filepath filesep 'sondata' filesep FirstLogProject filesep 'SimulationStatus.log'];
if isfile(aSimlogfile_path)
    aFid = fopen(aSimlogfile_path,"w");
    fclose(aFid);
end
% Clean the project file.
% This function sometimes breaks the automation software, not sure why.
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
% Simulate the project.
Project.simulate();
pause(0.5);
%Kill any cmd display windows
[~,~]=system("taskkill /F /IM cmd.exe");

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

        % Reset the log file
        FirstLogProject = 'Empty';

        [Resonance, Q_Factor] = Auto_Sim(Project, upperbound, lowerbound);

        return


    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Detecting Crashes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Same as the .csv Excel file, we should monitor it's existence.

log_startTime = tic;
while true

    log_elapsedTime = toc(log_startTime);

    % if the log file exists, break from the while loop
    if isfile(aSimlogfile_path)
        disp("Log File found")

        break

        
    % If the creation of the log file takes longer than 30 seconds, re-run
    % the simulation
    elseif log_elapsedTime > 30
        % close sonnet
        [~,~]=system("taskkill /F /IM sonnet.exe");

        % Reset the log file
        FirstLogProject = 'Empty';
        [Resonance, Q_Factor] = Auto_Sim(Project, upperbound, lowerbound);

        return
        
    
    end
end

% To avoid random errors where Sonnet finishes it's simulation but doesn't
% finish the log file, we check the excel file has enough data points once 
% every minute

Excel_Clock = tic;

% Search the file to see if we are done with the simulation
while true
    
    aTxtFile = fileread(aSimlogfile_path);
    % Monitor the last time the SimulationStatus.log file has been
    % accessed.
    files = dir(aSimlogfile_path);
    date_number=files.datenum;
    Modified_time = (minute(date_number)*60 + second(date_number));
    Current_time = (minute(datetime("now"))*60)+second(datetime("now"));
    check_time =  abs(Current_time- Modified_time);

    % Clock to check the excel file has enough data points
    Excel_Check = toc(Excel_Clock);
 
    if contains(aTxtFile,"Analysis stopped.")
        
        disp("Analysis stopped");
        [Resonance, Q_Factor] = Auto_Sim(Project, upperbound+0.1, lowerbound-0.1, FirstLogProject);
        return
    end
    
    if contains(aTxtFile,"EM abnormally terminated.")
        
        disp("EM abnormally terminated");       
        upperbound = ceil(upperbound);
        lowerbound = floor(lowerbound);
        [Resonance, Q_Factor] = Auto_Sim(Project, upperbound, lowerbound);
        return
    end
    if check_time > round(Time_Limit/4) || (Excel_Check/60) >= 1
        % If the last time the Simulation logfile has been accessed is over
        % 25% of the maximum time limit, then test to see if the .csv Excel
        % file produced has enough data points to perform meaningful data
        % extraction
        % First, extract the number of frequencies that were successfully
        % simulated in the .csv file
        csvname = erase(Project.Filename, ".son") + ".csv" ;
        
        T=readmatrix(csvname);
        Frequency = T(1:end,1);

        % Reset the Excel clock

        Excel_Clock = tic;
        % If the number of frequencies is above 2,000 (For an ABS Sweep in
        % Sonnet, extra discrete frequencies are performed. According to
        % Sonnet's User Manual, 2000 frequency points is the recommended
        % anmount of points for a frequency sweep for meaningful
        % S-parameter simulations.
        if numel(Frequency) >= 2000
            % Enough points are in the .csv file to extract data
            [Resonance, Q_Factor] = Auto_Extract(Project)
            copyfile(aSimlogfile_path);
            newLogname = num2str(Resonance*1000) + "MHz.log";
            movefile("SimulationStatus.log", newLogname);
            aFid = fopen(aSimlogfile_path,"w");
            fclose(aFid);
            movefile(newLogname, "Simulation Logs\");
            return
        else
            % Something occurred that made the simulation fail to produce
            % enough data points, so just repeat simulation

            % close sonnet
            [~,~]=system("taskkill /F /IM sonnet.exe");
            
            % Reset the log file
            FirstLogProject = 'Empty';

            % Re-run the simulation
            [Resonance, Q_Factor] = Auto_Sim(Project, upperbound, lowerbound);
            return
        end
        % If the file does not have enough points yet, we should introduce
        % a pause statement as if we continuosly open to .csv file, Sonnet
        % will produce errors in the simulation queue.
    end
    % If SimulationStatus.log contains the lines "Analysis completed
    % successfully." & "Analysis is 100 percent complete", start data
    % extraction. 
    % OR
    % If the last time the SimulationStatus.log file has been accessed
    % exceeds the maximum simulation time, try to extract data from the
    % .csv file anyways.
    if (contains(aTxtFile,"Analysis completed successfully.") && contains(aTxtFile,"Analysis is 100 percent complete")) 
             
        [Resonance, Q_Factor] = Auto_Extract(Project)
        copyfile(aSimlogfile_path, cd);
        newLogname = num2str(Resonance*1000) + "MHz.log";
        movefile("SimulationStatus.log", newLogname);
        movefile(newLogname, "Simulation Logs\");
        return
    end
end
end