function[out]=zf_02_read_returns(filename,folder)
warning_id='MATLAB:table:ModifiedAndSavedVarnames'; % No modified name warning
warning('off',warning_id);
data=readtable(fullfile(folder,filename)); % Read file
warning('on',warning_id);

if ismember('EffectiveDate',data.Properties.VariableNames) % Same column naming
    data=renamevars(data,'EffectiveDate','Date');
end
data.Date=datetime(data.Date,'InputFormat','MM/dd/yyyy','Format','dd-MMM-yyyy');
data=renamevars(data,2,'Price');

if ~isa(data.Price,'double')
    data.Price=replace(data.Price,',','');
    data.Price=str2double(data.Price); % Price
end
data=sortrows(data,'Date','ascend'); % Sort by date before log returns
data.Ret=log(data.Price./lagmatrix(data.Price,1))*100; % Log returns
data.AssetName=repmat({replace(filename,'.csv','')},size(data,1),1);
data=data(:,{'Date','Ret','AssetName'});

out=data;
end