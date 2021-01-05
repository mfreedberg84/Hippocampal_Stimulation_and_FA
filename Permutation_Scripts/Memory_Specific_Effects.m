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
Tracts_Data = DTI_Data(:,[4:8]);
OD_Data = [DTI_Data(:,10) DTI_Data(:,12)];
OW_Data = [DTI_Data(:,11) DTI_Data(:,13)];
disp('***** Data loaded ****');
%% Memory Analysis
Tracts = {'Tract1', 'Tract2', 'Tract3', 'Tract4', 'Tract5'};
Time_Points = {'One-day', 'One-Week'};
for k=1:length(Tracts)
    for l=1:length(Time_Points)
        Group = 1; 
        GName = 'IPC'; 
        disp(' --- ');
        disp(' --- ');
        disp(' --- ');
        disp(['Performing ' GName ':' table2array(Tracts(1,k)) '-' table2array(Time_Points(1,l)) ' analyses...']);
        % Make data table
        if strcmp(table2array(Time_Points(l)), 'One-day')
            Episodic_Memory_Data = [DTI_Data(:,1) Tracts_Data(:,k) OD_Data(:,1)];
            Procedural_Memory_Data = [DTI_Data(:,1) Tracts_Data(:,k) OD_Data(:,2)];
        else
            Episodic_Memory_Data = [DTI_Data(:,1) Tracts_Data(:,k) OW_Data(:,1)];
            Procedural_Memory_Data = [DTI_Data(:,1) Tracts_Data(:,k) OW_Data(:,2)];
        end
        % Eliminate NaNs for Episodic Memory Data
        Episodic_Cut = Episodic_Memory_Data(~isnan(Episodic_Memory_Data(:,3)),:);
        % Eliminate NaNs for Procedural Memory Data
        Procedural_Cut = Procedural_Memory_Data(~isnan(Procedural_Memory_Data(:,3)),:);
        % Eliminate NaNs for FA values
        Episodic_FA_Cut = Episodic_Cut(~isnan(Episodic_Cut(:,2)),:);
        Procedural_FA_Cut = Procedural_Cut(~isnan(Procedural_Cut(:,2)),:);
        % Isolate IPC Group
        IPC_Ep_Data = Episodic_FA_Cut(Episodic_FA_Cut(:,1) == Group, :);
        IPC_Proc_Data = Procedural_FA_Cut(Procedural_FA_Cut(:,1) == Group, :);
        % Calculate degrees of freedom for both correlations
        dof_Ep = length(IPC_Ep_Data)-2;
        dof_Proc = length(IPC_Proc_Data)-2;
        % Correlation for Episodic Memory
        [Rho_Ep Ep_p] = corr(IPC_Ep_Data(:,2), IPC_Ep_Data(:,3),'Type',CorrType);
        % Correlation for Procedural Memory
        [Rho_Proc Proc_p] = corr(IPC_Proc_Data(:,2), IPC_Proc_Data(:,3),'Type',CorrType);
        % Contrast correlations
        [p, zobs, za, zb] = corr_rtest(Rho_Ep, Rho_Proc, length(IPC_Ep_Data), length(IPC_Proc_Data));
        Rho_Diff_obs = za-zb;
        disp(' ---- Correlations and contrast ---- ');
        disp(['Episodic Correlation: r(' num2str(dof_Ep) ')= ' num2str(Rho_Ep) ', p = ' num2str(Ep_p)]);
        disp(['Procedural Correlation: r(' num2str(dof_Proc) ')= ' num2str(Rho_Proc) ', p = ' num2str(Proc_p)]);
        disp(['Observed difference between z(r) values is ' num2str(Rho_Diff_obs)]);
        % Make distribution of z statistics
        disp(' ---- Making distribution of z(r) values ---- ');
        for i=1:Sims
            % Make combined behavioral data table
            if strcmp(table2array(Time_Points(l)), 'One-day')
                Behavioral_Data = OD_Data;
            else
                Behavioral_Data = OW_Data;
            end
            % Shuffle Data
            for j=1:length(Behavioral_Data)
                Shuffle = randperm(2);
                Perm_Data(j,[1:4]) = [DTI_Data(j,1) Tracts_Data(j,k) Behavioral_Data(j,Shuffle(1,1)) Behavioral_Data(j,Shuffle(1,2))];
            end
            % Cut out Nans from Episodic data
            Ep_Perm_Data = Perm_Data(:,[1:3]);
            Ep_Cut = Ep_Perm_Data(~isnan(Ep_Perm_Data(:,3)),:);
            % Cut out Nans from Procedural data
            Proc_Perm_Data = [Perm_Data(:,[1:2]) Perm_Data(:,4)];
            Proc_Cut = Proc_Perm_Data(~isnan(Proc_Perm_Data(:,3)),:);
            % Eliminate Nans from FA data
            Ep_FA_Cut = Ep_Cut(~isnan(Ep_Cut(:,2)),:);
            Proc_FA_Cut = Proc_Cut(~isnan(Proc_Cut(:,2)),:);
            % Isolate IPC data
            IPC_Ep_Perm = Ep_FA_Cut(Ep_FA_Cut(:,1) == Group, :);
            IPC_Proc_Perm = Proc_FA_Cut(Proc_FA_Cut(:,1) == Group, :);
            % Count number of subjects for each correlation
            NumbEp = length(IPC_Ep_Perm);
            NumbProc = length(IPC_Proc_Perm);
            % Correlation for Episodic Memory
            [Rho_Ep Ep_p] = corr(IPC_Ep_Perm(:,2), IPC_Ep_Perm(:,3),'Type',CorrType);
            % Correlation for Procedural Memory
            [Rho_Proc Proc_p] = corr(IPC_Proc_Perm(:,2), IPC_Proc_Perm(:,3),'Type',CorrType);
            % Contrast correlations
            [p, z, za, zb] = corr_rtest(Rho_Ep, Rho_Proc, NumbEp, NumbProc);
            % Calculate difference in Rhos
            Rho_Diff = za-zb;
            % Add to distribution values
            Distribution_Value(i) = Rho_Diff;
            clear Behavioral_Data Shuffle Perm_Data Ep_Perm_Data Proc_Perm_Data Ep_Cut Proc_Cut Ep_FA_Cut Proc_FA_Cut IPC_Ep_Perm IPC_Proc_Perm NumbEp Numbproc Rho_Ep Ep_p Rho_Proc Proc_p p z za zb Rho_Diff;
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
    clear Episodic_Memory_Data Procedural_Memory_Data Episodic_Cut Procedural_Cut Episodic_FA_Cut Procedural_FA_Cut IPC_Ep_Data IPC_Proc_Data Rho_Ep Rho_Proc Ep_p Proc_p Rho_Diff_obs
end
Final_Table = [WO_Tables(1).matrix; WO_Tables(2).matrix; WO_Tables(3).matrix; WO_Tables(4).matrix; WO_Tables(5).matrix];
save('Memory_Effects.txt', 'Final_Table', '-ascii');

%% End program
disp('xxxxxxxxxxxxxxxxxxxx');
disp('Permuations Complete');
disp('xxxxxxxxxxxxxxxxxxxx');