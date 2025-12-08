function doallanalysis(analyzer)
    % 0. データセット宣言
    specA.SetName     = 'VR-ON'; 
    specB.SetName     = 'VR-OFF';
    
    % 1. Frequency
    specA.TargetData  = 'RowHMSPT'; 
    specB.TargetData  = 'RowHMSPT';
    
    analyzer.plotHistogram(specA,0);
    analyzer.plotHistogram(specA,1);
    
    analyzer.plotHistogram(specB,0);
    analyzer.plotHistogram(specB,1);
    
    % 2. Scatter
    specA.TargetData  = 'ZsH'; 
    specA.ErrorData   = 'error_ZsH'; 
    specB.TargetData  = 'ZsH';
    specB.ErrorData   = 'error_ZsH';
    analyzer.plotScatter(specA,specB, ...
        "Property","GRI","HdrSet","HDRNum_30","Amp",1.5,"PreDim",1,"Mode",1);
    
    specA.TargetData  = 'ZsHM'; 
    specA.ErrorData   = 'error_ZsHM';
    specB.TargetData  = 'ZsHM';
    specB.ErrorData   = 'error_ZsHM';
    analyzer.plotScatter(specA,specB,"Mode",2,"Amp",0.75);
    
    specA.TargetData  = 'ZsHS'; 
    specA.ErrorData   = 'error_ZsHS';
    specB.TargetData  = 'ZsHS';
    specB.ErrorData   = 'error_ZsHS';
    analyzer.plotScatter(specA,specB,"Mode",3,"Amp",0.75);
    
    specA.TargetData  = 'ZsHMS'; 
    specA.ErrorData   = 'error_ZsHMS';
    specB.TargetData  = 'ZsHMS';
    specB.ErrorData   = 'error_ZsHMS';
    analyzer.plotScatter(specA,specB,"Mode",4,"Amp",0.75);
    
    % 3. Significance
    specA.TargetData = 'RowHMSPT';
    specB.TargetData = 'RowHMSPT';
    numBootstrap = 1000;
    analyzer.plotCorrBootstrap(specA,specB,"Mode",1,"Bootstrap",numBootstrap);
    
    analyzer.plotCorrBootstrap(specA,specB,"Mode",2,"Bootstrap",numBootstrap);
    
    analyzer.plotCorrBootstrap(specA,specB,"Mode",3,"Bootstrap",numBootstrap);
    
    analyzer.plotCorrBootstrap(specA,specB,"Mode",4,"Bootstrap",numBootstrap);
    
    specC.SetName = 'LumModel';
    specC.TargetData = 'lummodelH';
    analyzer.plotCorrBootstrap_model(specA,specB,specC,"Mode",1,"Bootstrap",numBootstrap);
    
    %4 Residuals
    specA.TargetData = 'ZsH';
    specB.TargetData = 'ZsH';
    analyzer.plotResiduals(specA,specB,"Property",'GRI',"Amp",1.5);
    
    specA.TargetData = 'ZsHM';
    specB.TargetData = 'ZsHM';
    analyzer.plotResiduals(specA,specB,"Property",'GRI',"Amp",1.5,'Mode',2);
    
    specA.TargetData = 'ZsHS';
    specB.TargetData = 'ZsHS';
    analyzer.plotResiduals(specA,specB,"Property",'GRI',"Amp",1.5,'Mode',3);
    
    specA.TargetData = 'ZsHMS';
    specB.TargetData = 'ZsHMS';
    analyzer.plotResiduals(specA,specB,"Property",'GRI',"Amp",1.5);
    
    specA.TargetData = 'RowH';
    specB.TargetData = 'RowH';
    analyzer.plotResiduals(specA,specB,"Property",'Gross');
end
