function[moe_calc]=updateMOE(sample,moe)
    y=moe(~isnan(moe));
    x=1./sqrt(sample(~isnan(moe)));
    x=[ones(size(x,1),1),x];
    beta=(x'*x)\(x'*y);
    moe(isnan(moe))=beta(1)+beta(2)./sqrt(sample(isnan(moe)));
    moe_calc=moe;
end