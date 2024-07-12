
        CREATE TABLE IF NOT EXISTS sdsfie.DAM
        (categoryOfDam character varying ,
condition character varying ,
cwmsLocationId character varying ,
damIdpk character varying ,
dateEnd timestamp ,
dateStart timestamp ,
featureDescription character varying ,
featureName character varying ,
impoundmentName character varying ,
informationInNationalLanguage character varying ,
mediaId character varying ,
metadataId character varying ,
natureOfConstruction character varying ,
nidId integer ,
objectNameInNationalLanguage character varying ,
periodicDateEnd timestamp ,
periodicDateStart timestamp ,
pictorialRepresentation character varying ,
propertyIdCode character varying ,
rpsuid integer ,
rpuid character varying ,
scaleMinimum integer ,
sdsId uuid  PRIMARY KEY DEFAULT uuid_generate_v4() ,
sourceDate timestamp ,
sourceIndication character varying ,
textDescriptInNationalLanguage character varying ,
textualDescription character varying ,
watercourseName character varying 
) TABLESPACE pg_default;
 
               
        ALTER TABLE IF EXISTS sdsfie.DAM
            OWNER to catalog;  