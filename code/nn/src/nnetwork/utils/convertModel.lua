require 'torch'
require 'dp'
require 'src.nnetwork.utils.utilsFunction'
require 'src.nnetwork.BCECriterion'
require 'src.nnetwork.dpExtension.SaveModelToFile'
require 'src.nnetwork.dpExtension.feedback.CriterionFB'
require 'src.nnetwork.dpExtension.model.ExtNeural'
require 'src.nnetwork.dpExtension.loss.maskedCriterion'
require 'src.nnetwork.nnExtension.NoAvgBCECriterion'
require 'src.nnetwork.nnExtension.NoAvgBCECriterion1D'

model = torch.load('/project/mt_magicb/project/user/dnguyen/masterThesis/data/MT-EN-FR-HALF2/5000.combined/67.dropout.continued.model.th7')
torch.save('test.model.th7',model:double())