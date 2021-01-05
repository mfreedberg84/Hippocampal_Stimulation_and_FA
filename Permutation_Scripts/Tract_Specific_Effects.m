clear;clc
disp('--------------- Starting DTI Analysis ------------------');
%% Analyze DTI data. Data include two groups: IPC (n = 24) and Vertex (n=11). 
% 12 IPC and 11 Vertex subjects have behavioral change data one day (Post) and one week (Follow-up) after stimulation. 
% All subjects have rsFC change data and baseline DTI FA data for the IPC-Parahippocampal (Tract1) 
% Parahippocampal-Entorhinal (Tract2), Entorhinal-Hippocampal (Tract3), IPC-Hippocampal (Tract4), and 
% IPC-Precuneus pathways (Tract5). Run this script in the same folder as
% the "Hippoampal_Enhancement_and_FA_Data.csv" file. You must specify a
% drive to locate the "corr_rtest.m" downloaded function. NaNs in data file
% represent either outlier data or a failure to trace that tract.
% Add matlab toolbox drive% Add matlab toolbox drive
MTLAB_dir = '';
addpath(MTLAB_dir);
%Number of simulations for each permutation test
Sims = 50000;
% Spearman or Pearson
CorrType = 'Spearman';
disp('***** Starting variables loaded ****');
%% Load in data
DTI_Data = csvread('Hippocampal_Enhancement_and_FA_Data.csv');
% Organization of data file:
% Column 1: Group (1 = IPC, 2 = Vertex)
% Column 2: Participant Number
% Column 3: Hippocampal-Precuneus rsFC change data 
% Column 4: Tract1 FA (IPC-Parahippocampal)
% Column 5: Tract2 FA (Parahippocampal-Entorhinal)
% Column 6: Tract3 FA (Entorhinal-Hippocampal)
% Column 7: Tract5 FA (IPC-Hippocampal)
% Column 8: Tract6 FA (IPC-Precuneus)
% Column 9: Tract7 FA (IPC-Precentral; Control Tract)
% Column 10: Changes in episodic memory (1 day after stimulation)
% Column 11: Changes in episodic memory (1 week after stimulation)
% Column 12: Changes in procedural memory (1 day after stimulation)
% Column 13: changes in procedural memory (1 week after stimulation)

% Isolate Tracks Data
Tract_Data = DTI_Data(:,[4:8]);
Outcome_Data = [DTI_Data(:,3)  DTI_Data(:,[10:11])];
Control_Tract = DTI_Data(:,9);
disp('***** Data loaded ****');
%% Memory Analysis
Tracts = {'Tract1', 'Tract2', 'Tract3' ,'Tract4','Tract5'};
Outcomes = {'RSFC' 'Episodic_Post', 'Episodic_Follow-Up'};
for k=1:length(Tracts)
    for l=1:length(Outcomes)
        Group = 1; 
        GName = 'IPC';
        disp(' --- ');
        disp(' --- ');
        disp(' --- ');
        disp(['Performing ' GName ':' table2array(Tracts(1,k)) '-' table2array(Outcomes(1,l)) ' analyses...']);
        % Make data tables
        Experimental_Tract_Data = [DTI_Data(:,1) Tract_Data(:,k) Outcome_Data(:,l)];
        Control_Tract_Data = [DTI_Data(:,1) Control_Tract Outcome_Data(:,l)];
        % Get rid of NaNs in outcome data 
        Experimental_Cut = Experimental_Tract_Data(~isnan(Experimental_Tract_Data(:,3)),:);
        Control_Cut = Control_Tract_Data(~isnan(Control_Tract_Data(:,3)),:);
        % Get rid of NaNs in control tract
        Exp_Cut2 = Experimental_Cut(~isnan(Experimental_Cut(:,2)),:);
        Con_Cut2 = Control_Cut(~isnan(Control_Cut(:,2)),:);
        % Isolate data for IPC group
        IPC_Exp_Data = Exp_Cut2(Exp_Cut2(:,1) == Group, :);
        IPC_Con_Data = Con_Cut2(Con_Cut2(:,1) == Group, :);
        % Calculate degrees of freedom for both tracts
        dof_Exp = length(IPC_Exp_Data)-2;
        dof_Con = length(IPC_Con_Data)-2;
        % Correlation for Experimental Tract
        [Rho_Exp Exp_p] = corr(IPC_Exp_Data(:,2), IPC_Exp_Data(:,3),'Type',CorrType);
        % Correlation for Con
        [Rho_Con Con_p] = corr(IPC_Con_Data(:,2), IPC_Con_Data(:,3),'Type',CorrType);
        % Contrast correlations
        [p, zobs, za, zb] = corr_rtest(Rho_Exp, Rho_Con, length(IPC_Exp_Data), length(IPC_Con_Data));
        Rho_Diff_obs = za-zb;
        disp(' ---- Correlations and contrast ---- ');
        disp(['Exp Correlation: r(' num2str(dof_Exp) ')= ' num2str(Rho_Exp) ', p = ' num2str(Exp_p)]);
        disp(['Con Correlation: r(' num2str(dof_Con) ')= ' num2str(Rho_Con) ', p = ' num2str(Con_p)]);
        disp(['Observed difference between z(r) values is ' num2str(Rho_Diff_obs)]);
        % Make distribution of z-statistics
        disp(' ---- Making distribution of z(r) values ---- ');
        for i=1:Sims
            % Make combined tract data table
            Tract_Data_Combined = [Tract_Data(:,k) Control_Tract];
            % Shuffle Data
            for j=1:length(Tract_Data_Combined)
                Shuffle = randperm(2);
                Perm_Data(j,[1:4]) = [DTI_Data(j,1) Tract_Data_Combined(j,Shuffle(1,1)) Tract_Data_Combined(j,Shuffle(1,2)) Outcome_Data(j,l)];
            end
            % Cut out Nans from Experimental tract data
            Exp_Perm_Data = [Perm_Data(:,[1:2]) Perm_Data(:,4)];
            Exp_Cut = Exp_Perm_Data(~isnan(Exp_Perm_Data(:,2)),:);
            % Cut out Nans from Control tract data
            Con_Perm_Data = [Perm_Data(:,1) Perm_Data(:,[3:4])];
            Con_Cut = Con_Perm_Data(~isnan(Con_Perm_Data(:,2)),:);
            % Cut out Nans from Outcome data
            Exp_FA_Cut = Exp_Cut(~isnan(Exp_Cut(:,3)),:);
            Con_FA_Cut = Con_Cut(~isnan(Con_Cut(:,3)),:);
            % Isolate IPC Group
            IPC_Exp_Perm = Exp_FA_Cut(Exp_FA_Cut(:,1) == Group, :);
            IPC_Con_Perm = Con_FA_Cut(Con_FA_Cut(:,1) == Group, :);
            % Count number of subjects
            NumbExp = length(IPC_Exp_Perm);
            NumbCon = length(IPC_Con_Perm);
            % Correlation for Exp
            [Rho_Exp Exp_p] = corr(IPC_Exp_Perm(:,2), IPC_Exp_Perm(:,3),'Type',CorrType);
            % Correlation for Con
            [Rho_Con Con_p] = corr(IPC_Con_Perm(:,2), IPC_Con_Perm(:,3),'Type',CorrType);
            % Contrast correlations
            [p, z, za, zb] = corr_rtest(Rho_Exp, Rho_Con, NumbExp, NumbCon);
            % Calculate difference in Rhos
            Rho_Diff = za-zb;
            % Add to distribution value
            Distribution_Value(i) = Rho_Diff;
            clear Tract_Data_Combined Perm_Data Exp_Perm_Data Con_Perm_Data Exp_Cut Con_Cut Exp_FA_Cut Con_FA_Cut IPC_Exp_Perm IPC_Con_Perm;
        end
        %% Create histogram
        %hist(Distribution_Value,100);
        %hold on;
        %line([Rho_Diff_obs, Rho_Diff_obs],ylim, 'LineWidth', 2, 'Color', 'r');
        % Calculate the percentage of distrubution values greater than the
        % Zobs value.
        Permp = sum(Distribution_Value>Rho_Diff_obs)/Sims;
        if Rho_Diff_obs<prctile(Distribution_Value, 95); disp(' x x x No Group Differences x x x '); else; disp(' x x x SIGNIFICANT GROUP DIFFERENCE!!! x x x '); end;
        disp(['Observed difference is ' num2str(Rho_Diff_obs) ' and upper 5% starts at ' num2str(prctile(Distribution_Value,95)) ', p = ' num2str(Permp)]);
        %pause;
        %close;
        % Record essential information.
        WO_Tables(k).matrix(l,[1:5]) = [k,l, Rho_Diff_obs, prctile(Distribution_Value,95), Permp];
    end
    clear Experimental_Tract_Data Control_Tract_Data Experimental_Cut Control_Cut Experimental_FA_Cut Control_FA_Cut IPC_Exp_Data IPC_Con_Data;
end
Final_Table = [WO_Tables(1).matrix; WO_Tables(2).matrix; WO_Tables(3).matrix; WO_Tables(4).matrix; WO_Tables(5).matrix];
save('Tract_Effects.txt', 'Final_Table', '-ascii');
%% End program
disp('xxxxxxxxxxxxxxxxxxxxx');
disp('Permutations Complete');
disp('xxxxxxxxxxxxxxxxxxxxx');
