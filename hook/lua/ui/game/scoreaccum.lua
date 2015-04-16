local originalUpdateScoreData = UpdateScoreData
function UpdateScoreData(newData)
  	originalUpdateScoreData(newData)
	import('/mods/common/score.lua').Update(newData)
end
