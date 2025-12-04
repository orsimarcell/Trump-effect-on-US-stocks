%% Preprocessing return data
clear; close all; clc
% We have separate tables for the different indeces/stocks.

%% Load raw data
stocksFiles=dir(fullfile(pwd,'Raw data','stocks','*.csv')); % Files list
indecesFiles=dir(fullfile(pwd,'Raw data','indeces','*.csv'));
stockspp=cell(size(stocksFiles)); % Read files
for i=1:size(stockspp,1)
    stockspp{i}=zf_02_read_returns(stocksFiles(i).name,stocksFiles(i).folder);
end
indecespp=cell(size(indecesFiles));
for i=1:size(indecespp,1)
    indecespp{i}=zf_02_read_returns(indecesFiles(i).name,indecesFiles(i).folder);
end

%% Merge and save data
tickersAll=[stockspp;indecespp];
returnsLong=vertcat(tickersAll{:}); % Merge data tables
returnsLong=returnsLong(~isnan(returnsLong.Ret),:); % Delete NaN
returnsLong=sortrows(returnsLong,'Date','ascend');
returns=unstack(returnsLong,'Ret','AssetName');
save('Preprocessed data\returns.mat','returns');
