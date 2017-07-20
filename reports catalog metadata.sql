
;WITH cteCatalog ([Path], Name, [Description], CreationDate, ModifiedDate, AverageRowCount, AverageDuration_sec, XML, row)
as (
		SELECT 
			[Path], Name, [Description], CreationDate, ModifiedDate, AverageRowCount = AVG(e.[RowCount]) OVER (Partition By [Path], Name)
		,	AverageDuration_sec = (AVG(e.timedataretrieval + e.timeprocessing + e.TimeRendering) OVER (Partition By [Path], Name))/1000.0
		,	XML	= CONVERT(XML,C.Parameter)
		,	Row	= ROW_NUMBER () OVER (Partition BY Path, Name order by path, name)
        from Catalog c
		inner join ExecutionLog2 e 
		on e.ReportPath = c.Path
)
SELECT  distinct
			[Path], Name, [Description], CreationDate, ModifiedDate, AverageRowCount
		,	AverageDuration_sec =	round(AverageDuration_sec,2)
		,	Param_Name			= ParamXML.value('Name[1]', 'VARCHAR(250)')  
		,	Param_DataType		= ParamXML.value('Type[1]', 'VARCHAR(250)')  
		,	Param_Nullable		= ParamXML.value('Nullable[1]', 'VARCHAR(250)')  
		,	Param_AllowBlank	= ParamXML.value('AllowBlank[1]', 'VARCHAR(250)')  
		,	Param_MultiValue	= ParamXML.value('MultiValue[1]', 'VARCHAR(250)')  
		,	Param_UsedInQuery	= ParamXML.value('UsedInQuery[1]', 'VARCHAR(250)')  
		,	Param_Prompt		= ParamXML.value('Prompt[1]', 'VARCHAR(250)')  
		,	Param_DynamicPrompt = ParamXML.value('DynamicPrompt[1]', 'VARCHAR(250)')  
		,	Param_PromptUser	= ParamXML.value('PromptUser[1]', 'VARCHAR(250)')  
		,	Param_State			= ParamXML.value('State[1]', 'VARCHAR(250)')  
 FROM cteCatalog c
CROSS APPLY c.XML.nodes('//Parameters/Parameter') p ( ParamXML ) 
WHERE c.row = 1
order by AverageDuration_sec desc