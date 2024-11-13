clear all;

material = ["cu" "pla" "glass"];
mesh = ["sphere" "bunny" "dragon" "board_ang0_size0" "board_ang0_size03" "board_ang0_size015" "board_ang30_size0" "board_ang30_size03" "board_ang30_size015"];
mesh_mk = ["sphere" "bunny" "dragon" "board_ang0_size0" "board_ang0_size03" "board_ang0_size015" "board_ang30_size0" "board_ang30_size03" "board_ang30_size015", "makihiraA", "makihiraB", "makihiraC"];
roughness = ["0.025" "0.129"; "0.075" "0.225"; "0.05" "0.5"];
[~,materialNum] = size(material);
[~,meshNum] = size(mesh);
[~,meshNum_withmk] = size(mesh_mk);
[~,roughnessNum] = size(roughness);

experiment_condition = [];
for material_type=1:materialNum
    for shape_type=1:meshNum
        for gloss_type=1:roughnessNum
            experiment_condition = [experiment_condition; material(material_type), mesh(shape_type), roughness(material_type, gloss_type)];
        end
    end
end

save('z_conditionList', 'experiment_condition');


experiment_condition = [];
for material_type=1:materialNum
    for shape_type=1:meshNum_withmk
        for gloss_type=1:roughnessNum
            experiment_condition = [experiment_condition; material(material_type), mesh_mk(shape_type), roughness(material_type, gloss_type)];
        end
    end
end

save('z_conditionList_withMK', 'experiment_condition');

 