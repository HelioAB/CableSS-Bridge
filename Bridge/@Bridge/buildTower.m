function tower = buildTower(obj,CoordBottom,CoordTop,L,section,material,element_type,division_num,options)
    arguments
        obj
        CoordBottom
        CoordTop
        L
        section
        material
        element_type = Beam188
        division_num = 5
        options.Name {mustBeText} = ''
    end
    tower = Tower(CoordBottom,CoordTop,L,section,material);
    tower.ElementType = element_type;
    tower.ElementDivisionNum = division_num;
    tower.record;
    section.unique.record;
    material.record;
    element_type.record;

    obj.updateList('Structure',tower,'Section',section.unique, ...
                    'Material',material,'ElementType',element_type,'ElementDivision',division_num)
    obj.editStructureName(tower,options.Name)
end