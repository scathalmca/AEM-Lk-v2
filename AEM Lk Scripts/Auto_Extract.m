function [Resonance, Q_Factor] = Auto_Extract(Project)
%  AUTO_EXTRACT2 Brief summary of this function.
% 
% Detailed explanation of this function.
csvname = erase(Project.Filename, ".son") + ".csv" ;
T=readmatrix(csvname);
Frequency = T(1:end,1);
S21= T(1:end, 6);
TF_min = islocalmin(S21(S21<0.9));
local_minima=S21(TF_min);
upperbound = Frequency(end);
lowerbound = Frequency(1);
if (upperbound<=1) || (lowerbound<=1)
    upperbound = round(Frequency(end),4)+1;
    lowerbound = 1.001;
end
index = find(S21==min(S21));
Resonance=Frequency(index);
% Check if any resonant frequencies exist in the frequency range or if S21
% suddenly drops anywhere away from resonance.
if (isempty(local_minima)==1 && S21(end) == min(S21)) 
    % No resonance detected
    disp("No resonance detected...")
    upperbound = upperbound+1;
    lowerbound = lowerbound-1;
    [Resonance, Q_Factor] = Auto_Sim(Project, upperbound,lowerbound);
    return
elseif S21(end) == min(S21)
    % Resonance exists but S21 data drops after resonance (unlikely)
    disp("S21 drops off after resonance...")
    index1 = find(S21 == local_minima(1));
    upperbound =round(cast(Frequency(index1), "double") +0.05, 4);
    lowerbound =round(cast(Frequency(index1), "double") -0.05, 4);
    [Resonance, Q_Factor] = Auto_Sim(Project, upperbound, lowerbound);
    return
    
elseif numel(S21(S21>1.000005))~=0
    disp("S21 above 1!...")
    index = find(S21==min(S21));
    Resonance=round(Frequency(index),4);
    if upperbound == round(Resonance + 0.01,4)
        Remove_Index = S21>1;

        S21(Remove_Index) = [];
        Frequency(Remove_Index) = [];
    else
        upperbound = mean([Resonance upperbound]);
        lowerbound = mean([Resonance lowerbound]);

        [Resonance, Q_Factor] = Auto_Sim(Project, upperbound, lowerbound);
        return
    end
   
    
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Need to check that there is only one resonant frequency in the sweep to
% avoid any harmonics appearing in the simulations for large frequency
% sweeps.

% To achieve this, we have to assume that the lowest resonance dip in the
% sweep is what we are looking for
% We also need to ignore any dips below |S21| > 0.9 and assume these are
% not real resonant frequencies or harmonics.

Minima_Index = find(islocalmin(S21));

Minima_Below_Thres = Minima_Index(S21(Minima_Index)<0.9);

if length(Minima_Below_Thres) > 1
    % Find the lowest minimum

    lowestMinIdx = Minima_Below_Thres(1);

    % Assume the lowest minima is the correct resonant frequency 
    Resonance = Frequency(lowestMinIdx);

    upperbound = mean([Resonance upperbound]);
    lowerbound = mean([Resonance lowerbound]);

    [Resonance, Q_Factor] = Auto_Sim(Project, upperbound, lowerbound);
    return
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% If the data has passed all of the checks, can perform Q_Factor
% calculation.

index = find(S21==min(S21));
Resonance=round(Frequency(index),4);
% Resonance found and data is physical
HM=(max(S21)+min(S21))/2;
[xInt1]=intersections(Frequency(1:index), S21(1:index)-HM, Frequency(1:index), zeros(1,numel(S21(1:index))));
[xInt2]=intersections(Frequency(index:numel(Frequency)), S21(index:numel(S21))-HM, Frequency(index:numel(Frequency)), zeros(1,numel(S21(index:numel(S21)))));
while true
    if numel(xInt1) > numel(xInt2)
        diff=numel(xInt1)-numel(xInt2);
        xInt1(1:diff)=[];
    elseif numel(xInt1) < numel(xInt2)
        diff=numel(xInt2)-numel(xInt1);
        xInt2(numel(xInt2)-diff:end)=[];
    else
        break
    end
end
x=xInt2-xInt1;

try
    Q_Factor=Frequency(index)/x;

catch ME
    [Resonance, Q_Factor] = Auto_Sim(Project, upperbound-0.5, lowerbound+0.5);
end

clear Frequency S21 T
end