classdef AnalysisClass
    
    properties
        resultpath = "./results/";
        ana_result = "analysis/";
        Datapath = "./data/";

        MatNames1 = {'cu0025', 'cu0129', 'pla0075', 'pla0225'};
        MatNames2 = {'cu_0.025', 'cu_0.129', 'pla_0.075', 'pla_0.225'};
        MatNames3 = {'cu-0.025', 'cu-0.129', 'pla-0.075', 'pla-0.225'};
        HDRNames_15 = [19, 39, 78, 80, 102, 125, 152, 203, 226, 227, 230, 232, 243, 278, 281];
        HDRNames_30 = [5,19,34,39,42,43,78,80,102,105,125,152,164,183,198,201,202,203,209,222,226,227,230,232,243,259,272,278,281,282];
        HDRNum_15 = [2,4,7,8,9,11,12,18,21,22,23,24,25,28,29];
        HDRNum_30 = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30];
        ShapeNames = {'sphere','bunny','dragon','boardA','boardB','boardC'};
    end
    
    methods
        function obj = untitled2(inputArg1,inputArg2)

            obj.Property1 = inputArg1 + inputArg2;
        end
        
        function outputArg = method1(obj,inputArg)
 
            outputArg = obj.Property1 + inputArg;
        end
    end
end

