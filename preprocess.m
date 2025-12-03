function[dataOut]=preprocess(dataIn)
    data=dataIn(2:end,:); % Remove the first row for processing
    data.sample=str2double(regexprep(data.sample,'\s*[a-zA-Z]*$',''));
    data.date=datetime(strcat(num2str(data.year),'/',regexprep(data.date,{'^.*-\s'},{'',''})),'InputFormat','yyyy/M/d');
    data=data(~isnan(data.sample)|~isnan(data.moe),:);
    data=sortrows(data,'date','ascend');
    dataOut=data;
end