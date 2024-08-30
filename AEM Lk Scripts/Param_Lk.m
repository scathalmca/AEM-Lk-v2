function [KInductance, SimRes, SimQ, Project] = Param_Lk(Project, SimRes, SimQ, Measured_Res, iteration, Accuracy)
%  PARAM_LK Function to change the Lk value in a Sonnet Geometry file to match a specific 
% measured resonant frequency as close as possible.
% First, extract the current kinetic inductance value
KInductance=Project.GeometryBlock.ArrayOfMetalTypes{1}.KineticInductance;
% Store previous values
prev_resonance = SimRes;
prev_Q = SimQ;
prev_proj = Project.Filename;
% If the measured resonant frequency is higher then the simulated/designed
% resonance, the kinetic inductance is too high and must be lowered.
if Measured_Res > SimRes
    while true
        
        % Reduce the kinetic inductance by iteration(Either 1,0.1 or 0.01)
        Project.GeometryBlock.ArrayOfMetalTypes{1}.KineticInductance = Project.GeometryBlock.ArrayOfMetalTypes{1}.KineticInductance-iteration;
        % Give a temporary name to the new structure
        str=append('Lk_',num2str(Project.GeometryBlock.ArrayOfMetalTypes{1}.KineticInductance),'.son');
        %Save the file as "String".son
        Project.saveAs(str);
        % Increase the frequency bounds in the simulation
        upperbound = SimRes+0.5;
        lowerbound = SimRes-0.5;
        % Re initialise the project after renaming
        Project = SonnetProject(str);
        
        % Simulate the project
        [SimRes, SimQ] = Auto_Sim(Project, upperbound, lowerbound);
        % Rename file as resonant frequency
        old_son_file=str;
        str_son=num2str(SimRes*1000)+"MHz.son";
        str_csv_old=erase(str, ".son")+".csv";
        str_csv_new=num2str(SimRes*1000)+"MHz.csv";
        Project.saveAs(str_son);
        movefile(str_csv_old, str_csv_new);
        delete(old_son_file);
                
        % Check if the resonant frequency is as close to the measured
        % resonance as possible.
        if Measured_Res <= SimRes && Measured_Res >= prev_resonance
            % Determine is the current resonance or the previous
            % resonance is closer to the measured value
            close_f1 = abs(Measured_Res-SimRes);
            close_f2 = abs(Measured_Res-prev_resonance);
            % If the resonance is close and the kinetic inductance value is
            % correct to the user's chosen accuracy, return the function as
            % this is the correct value.
            if iteration == Accuracy
                if close_f1 <= close_f2
                    % Current kinetic inductance value
                    KInductance=Project.GeometryBlock.ArrayOfMetalTypes{1}.KineticInductance;

                    Project = SonnetProject(str_son);
                else
                    % Previous kinetic inductance value
                    KInductance=Project.GeometryBlock.ArrayOfMetalTypes{1}.KineticInductance+iteration;
                    
                    Project = SonnetProject(prev_proj);
                    Project.GeometryBlock.ArrayOfMetalTypes{1}.KineticInductance = KInductance;
                end
                return
            % Else, determine what values to use in the next iteration
            % and reduce the iteration by 10
            else
                % If the current resonance is closer, start from that value
                if close_f1 < close_f2
                    [KInductance, SimRes, SimQ, Project] = Param_Lk(Project, SimRes, SimQ, Measured_Res, iteration/10, Accuracy);

                    return
                % Else the previous resonance is closer, start from that value
                else
                    [KInductance, SimRes, SimQ, Project] = Param_Lk(SonnetProject(prev_proj), prev_resonance, prev_Q, Measured_Res, iteration/10,Accuracy);

                    return
                end
            end
        end
        % If the resonance is still lower than the measured value, repeat
        % the while loop and reduce the kinetic inductance by iteration
        % again.
        % Store current values as previous values for the next loop
        % Resonant Frequency for the next loop
        prev_resonance = SimRes;
        % Filename for the next loop
        prev_proj = str_son;
    end
% If the measured resonant frequency is lower then the simulated/designed
% resonance, the kinetic inductance is too low and must be highered.
elseif Measured_Res < SimRes
    while true
        % Increase the kinetic inductance by iteration(Either 1,0.1 or 0.01)
        Project.GeometryBlock.ArrayOfMetalTypes{1}.KineticInductance = Project.GeometryBlock.ArrayOfMetalTypes{1}.KineticInductance+iteration;
        % Give a temporary name to the new structure
        str=append('Lk_',num2str(Project.GeometryBlock.ArrayOfMetalTypes{1}.KineticInductance),'.son');
        %Save the file as "String".son
        Project.saveAs(str);
        % Increase the frequency bounds in the simulation
        upperbound = SimRes+0.5;
        lowerbound = SimRes-0.5;
        % Re initialise the project after renaming
        Project = SonnetProject(str);
        % Simulate the project
        [SimRes, SimQ] = Auto_Sim(Project, upperbound, lowerbound);
        % Rename file as resonant frequency
        old_son_file=str;
        str_son=num2str(SimRes*1000)+"MHz.son";
        str_csv_old=erase(str, ".son")+".csv";
        str_csv_new=num2str(SimRes*1000)+"MHz.csv";
        Project.saveAs(str_son);
        movefile(str_csv_old, str_csv_new);
        delete(old_son_file);
        % Check if the resonant frequency is as close to the measured
        % resonance as possible.
        if Measured_Res >= SimRes && Measured_Res <= prev_resonance
            % Determine is the current resonance or the previous
            % resonance is closer to the measured value
            close_f1 = abs(Measured_Res-SimRes);
            close_f2 = abs(Measured_Res-prev_resonance);
            % If the resonance is close and the kinetic inductance value is
            % correct to the user's chosen accuracy, return the function as
            % this is the correct value.
            if iteration == Accuracy
                if close_f1 <= close_f2
                    % Current kinetic inductance value
                    KInductance=Project.GeometryBlock.ArrayOfMetalTypes{1}.KineticInductance;

                    Project = SonnetProject(str_son);
                else
                    % Previous kinetic inductance value
                    KInductance=Project.GeometryBlock.ArrayOfMetalTypes{1}.KineticInductance-iteration;
                    Project = SonnetProject(prev_proj);
                    Project.GeometryBlock.ArrayOfMetalTypes{1}.KineticInductance = KInductance;
                end
                
                return
            % Else, determine what values to use in the next iteration
            % and reduce the iteration by 10
            else
                % If the current resonance is closer, start from that value
                if close_f1 < close_f2
                    [KInductance, SimRes, SimQ, Project] = Param_Lk(Project, SimRes, SimQ, Measured_Res, iteration/10, Accuracy);
                    
                    return
                % Else the previous resonance is closer, start from that value
                else
                    [KInductance, SimRes, SimQ, Project] = Param_Lk(SonnetProject(prev_proj), prev_resonance, prev_Q, Measured_Res, iteration/10, Accuracy);
                    
                    return
                end
            end
        end
        % If the resonance is still higher than the measured value, repeat
        % the while loop and increase the kinetic inductance by iteration
        % again.
        % Store current values as previous values for the next loop
        % Resonant Frequency for the next loop
        prev_resonance = SimRes;
        % Filename for the next loop
        prev_proj = str_son;
    end
end
end