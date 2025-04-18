function [] = AEM_Lk_Func(Filename, Accuracy, Fraction)
%  AEM_LK_FUNC Call function for AEM Lk.

clear global 

% Parameterises the Lk variable in Sonnet geometry files to match a user's measured
% resonant frequency in order to extract a kinetic inductance value from simulations
% (Lk)
% AEM Lk is designed to extract kinetic inductance values (*H/sq) from
% Sonnet simulations after characterisation of fabricated resonators,
% AEM Lk takes in a txt file containing the names of the Sonnet files of
% each resonator and the corresponding measured resonant frequency.
% Read .txt file and append filenames and resonant frequency values to
% seperate matrices.
[FileMatrix, ResMatrix] = ReadFile(Filename);
% Global variables
global f 
% As AEM Lk v2 uses a Log file to monitor the Sonnet simulations, need to
% intialise the global variable.

warning off
[~,check] = system('tasklist');
if contains(check, 'sonnet.exe')
    system('TASKKILL /IM sonnet.exe');
end
warning on

% The matrices below contain the final kinetic inductance value (*H/sq),
% simulated resonant frequency (that matches the measured resonance as
% close as possible) and the final Qc value.
KInductance = [];

% Array to save the resonant frequencies with Lk=0.
Geo_Res =[];
% Start the timer for the runtime
tic
% Count the number of simulations performed by Sonnet
SimCounter("new");
% Call function to create storage for all final values
EndResonators(0, 0, 0, "new");
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% To find our initial starting point (i.e. The initial designed
% frequencies), AEM Lk needs to simulate the initial geometries, then
% parameterise the Lk value in Sonnet afterwards.
% Display waitbar
f = waitbar(0);
Resonator_Num = 1;

for i = 1 : numel(FileMatrix)
    waitbar((Resonator_Num-1)/numel(FileMatrix), f, append("Extracting Lk...("+num2str(Resonator_Num)+" / "+num2str(numel(FileMatrix))+ ") : "+  FileMatrix(i)));
    % Initialise the project file
    Project = SonnetProject(char(FileMatrix(i)));

    % Save the project with a temporary name (Also makes a copy of the
    % original file)
    str=append("Test_",FileMatrix(i));

    % Measured resonances expected to be in MHz, while input in Sonnet is
    % set to GHz (For DIAS MKIDs), so set upper and lower frequency bounds
    % to be +-500MHz
    
    if str2double(cell2mat(ResMatrix(i)))/1000 <= 0.5
        upperbound = (str2double(cell2mat(ResMatrix(i)))/1000)+0.5;
        lowerbound = 0.001;
    else
        upperbound = (str2double(cell2mat(ResMatrix(i)))/1000)+0.5;
        lowerbound = (str2double(cell2mat(ResMatrix(i)))/1000)-0.5;
    end
    
    % If this is the first simulation, assume this will be the average time
    % it takes per simulation.
    % This is the Time Limit allowed per simulation that lets AEM Lk check
    % if the simulation has finished but any errors occurred outside of the
    % data file.
    if i==1

        Project.saveAs(str);
        % Reinitialize the project.
        Project = SonnetProject(str);

        [SimRes, SimQ] = Auto_Sim(Project, upperbound, lowerbound);

        % Set the first instance of the Lk as the initial value
        Lk = Project.GeometryBlock.ArrayOfMetalTypes{1}.KineticInductance;

    else
        % Change the kinetic inductance to the previous geometries Lk value
        % (Reduces number of simulations)
        Project.GeometryBlock.ArrayOfMetalTypes{1}.KineticInductance = round(Lk);

        Project.saveAs(str);
        % Reinitialize the project.
        Project = SonnetProject(str);
        [SimRes, SimQ] = Auto_Sim(Project, upperbound, lowerbound);
    end
    % Rename file as resonant frequency
    old_son_file=str;
    str_son=num2str(SimRes*1000)+"MHz.son";
    str_csv_old=erase(str, ".son")+".csv";
    str_csv_new=num2str(SimRes*1000)+"MHz.csv";
    Project.saveAs(str_son);
    movefile(str_csv_old, str_csv_new);
    delete(old_son_file);


    % Now we have a starting frequency for all of the simulated structures and
    % can find Lk values by varying Lk to match simulated resonance to measured
    % resonance.

    % Re initialise the simulation files
    Project = SonnetProject(str_son);
    % Current measured resonant frequency
    Measured_Res = (str2double(cell2mat(ResMatrix(i)))/1000);
    % Call function to parameterise the kinetic inductance value (Lk)
    [Lk, SimRes, ~, Project]=Param_Lk(Project, SimRes, SimQ, Measured_Res, 1, Accuracy);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % To achieve accurate values of Qc (not neccesary), do 10MHz
    % frequency sweep either side of the resonant frequency
    upperbound = SimRes + 0.01;
    lowerbound = SimRes - 0.01;

    % Error with SonnetLab that we need to decompile the project again
    % before simulating.

    Project = SonnetProject(Project.Filename);
    
    % Simulation for accuracy of Qc
    [SimRes, SimQ] = Auto_Sim(Project, upperbound, lowerbound);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Output is the closest kinetic inductance value, simulated
    % resonant frequency and simulated Qc value.
    % Store values in final EndResonators matrix
    EndResonators(SimRes, SimQ, convertCharsToStrings(Project.Filename), "add");

    % Array for storing correct Lk values
    KInductance = [KInductance  Lk];

    % Kill Sonnet when a parameterisation is finished as this refreshes
    % the job queue in the application
    [~,~]=system("taskkill /F /IM sonnet.exe");

   
    Resonator_Num = Resonator_Num + 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If the user wants to calculate the kinetic inductance fraction for each
% resonator:
Resonator_Num=0;

if Fraction == 1

    for i = 1 : numel(FileMatrix)
        waitbar((Resonator_Num-1)/numel(FileMatrix), f, append("Extracting kinetic inductance Fraction...("+num2str(Resonator_Num)+" / "+num2str(numel(FileMatrix))+ ") : "+  FileMatrix(i)));
        % Initialise the project file
        Project = SonnetProject(char(FileMatrix(i)));
    
        % Save the project with a temporary name (Also makes a copy of the
        % original file)
        str=append("Test_LkFraction_",FileMatrix(i));

        % Change the kinetic inductance to 0 in order to extract the
        % geometrical inductance
        Project.GeometryBlock.ArrayOfMetalTypes{1}.KineticInductance = 0;

        % Usually the resonant frequency of a resonator with Lk=0pH/sq will
        % be centered around 20GHz.

        upperbound = 21;
        lowerbound = 18;

        Project.saveAs(str);
        % Reinitialize the project.
        Project = SonnetProject(str);

        % The coupling Q of this resonator is not important and thus not
        % saved
        [LGeo_Res, ~] = Auto_Sim(Project, upperbound, lowerbound);

        % Rename file as resonant frequency
        old_son_file=str;
        str_son=num2str(LGeo_Res*1000)+"MHz.son";
        str_csv_old=erase(str, ".son")+".csv";
        str_csv_new=num2str(LGeo_Res*1000)+"MHz.csv";
        Project.saveAs(str_son);
        movefile(str_csv_old, str_csv_new);
        delete(old_son_file);

        Geo_Res = [LGeo_Res  Geo_Res];

        Resonator_Num = Resonator_Num + 1;

    end


end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Printing final values
% Get the number of simulations in total performed
Counter = SimCounter("get");
% Create data file
txtfile=fopen("Kinetic Inductance Data File.txt", "w+");
% Stop timer and calculate elapsed time for the automation
elapsedTime = toc;
% Calculate time in hours, minutes, and seconds
hours = num2str(floor(elapsedTime / 3600));
minutes = num2str(floor(mod(elapsedTime, 3600) / 60));
seconds = num2str(mod(elapsedTime, 60));
% Print the value to the file with a "|" separator
% Display runtime in format hours/minutes/seconds
fprintf(txtfile,'%s%s%s%s%s%s%s',"Runtime| ","Hours: ", hours,"  Minutes: ", minutes, "  Seconds: ",seconds);
fprintf(txtfile, "\n");
fprintf(txtfile,"%s%s", "Number of Simulations Performed: ", num2str(Counter));
fprintf(txtfile, "\n");
fprintf(txtfile,"%s%s%s", "Set Accuracy = ", num2str(Accuracy),"pH/sq");
fprintf(txtfile, "\n");
fprintf(txtfile,"%s", "Mean Lk =  ", num2str(mean(KInductance)), "pH/sq");
fprintf(txtfile, "\n");
fprintf(txtfile,"%s", "STD =  ", num2str(std(KInductance)), "pH/sq");
fprintf(txtfile, "\n");
fprintf(txtfile, "\n");
fprintf(txtfile, '%s%s', "|",repmat('_', 1, 4),"Design File", repmat('_', 1, 4));
fprintf(txtfile, '%s%s', "|",repmat('_', 1, 4),"Corrected File", repmat('_', 1, 4));
fprintf(txtfile, '%s%s', "|",repmat('_', 1, 4),"Measured Resonances(MHz)", repmat('_', 1, 4));
fprintf(txtfile, '%s%s', "|",repmat('_', 1, 4),"Simulated Resonances(MHz)", repmat('_', 1, 4));
fprintf(txtfile, '%s%s%s%s%s', "|",repmat('_', 1, 4),"Simulated Q-Factor", repmat('_', 1, 4));
fprintf(txtfile, '%s%s', "|",repmat('_', 1, 4),"Kinetic Inductance", repmat('_', 1, 4));
fprintf(txtfile, '%s', "|",repmat('_', 1, 4),"Lk Fraction", repmat('_', 1, 4), "|");
[all_Resonances, all_QFactors, all_Filenames] = EndResonators(0, 0, 0, "get");
mkdir FinishedSimulations
for i=1:numel(all_Resonances)

    % Calculating kinetic inductance fraction 
    Measured_Res = (str2double(cell2mat(ResMatrix(i)))/1000);
    x = (Geo_Res(i)/Measured_Res)^2;
    L_Geo = KInductance(i)/(x-1);

    Lk_Frac = KInductance(i)/(KInductance(i)+L_Geo);

    fprintf(txtfile, "\n");
    fprintf(txtfile, "%s %25s %25s %30.2f %30.2f %30.2f %20s", char(FileMatrix(i,:)), all_Filenames(i),char(ResMatrix(i,:)), all_Resonances(i)*1000,all_QFactors(i),KInductance(i),Lk_Frac);
    movefile(all_Filenames(i),'FinishedSimulations\');
    csv_name = erase(all_Filenames(i), ".son")+".csv";
    movefile(csv_name,'FinishedSimulations\');

end
fclose(txtfile);
% Change directory and make new folder
mkdir ExcessGeometries\
%Moving all excess geometries to seperate folder
movefile *MHz.son ExcessGeometries\
movefile *MHz.csv ExcessGeometries\
waitbar(1, f, "All Resonators Successfully Automated by AEM!");

end