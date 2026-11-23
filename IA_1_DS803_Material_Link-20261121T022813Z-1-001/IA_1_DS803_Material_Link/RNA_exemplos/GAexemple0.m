gaopt.PopulationSize = 100;
gaopt.Generations = 50;
gaopt.InitialPopulation  = [];
gaopt.MutationFcn = 0.15;
gaopt.EliteCount = 2;
%
x = gaGo(@(x) fit0(x, Md),40,gaopt);