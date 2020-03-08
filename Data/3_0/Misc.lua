local data = ...
-- From DefaultMonsterStats.dat
data.monsterEvasionTable = { 53, 67, 82, 97, 113, 130, 148, 166, 185, 205, 226, 248, 271, 295, 320, 346, 373, 401, 431, 462, 493, 527, 561, 597, 635, 674, 715, 757, 801, 846, 894, 943, 994, 1048, 1103, 1160, 1220, 1282, 1346, 1413, 1482, 1554, 1628, 1705, 1785, 1868, 1954, 2044, 2136, 2232, 2332, 2435, 2541, 2652, 2766, 2885, 3008, 3135, 3267, 3403, 3544, 3690, 3842, 3998, 4160, 4328, 4501, 4681, 4867, 5059, 5258, 5463, 5676, 5895, 6123, 6358, 6601, 6852, 7112, 7380, 7658, 7945, 8241, 8548, 8864, 9191, 9529, 9879, 10239, 10612, 10997, 11395, 11806, 12230, 12668, 13121, 13588, 14071, 14569, 15084, }
data.monsterAccuracyTable = { 14, 15, 15, 16, 17, 18, 19, 20, 21, 23, 24, 25, 26, 28, 29, 31, 32, 34, 35, 37, 39, 41, 43, 45, 47, 49, 52, 54, 57, 59, 62, 65, 68, 71, 74, 77, 81, 84, 88, 92, 96, 100, 105, 109, 114, 119, 124, 129, 135, 140, 146, 152, 159, 165, 172, 179, 187, 195, 203, 211, 220, 229, 238, 247, 257, 268, 279, 290, 301, 314, 326, 339, 352, 366, 381, 396, 412, 428, 444, 462, 480, 499, 518, 538, 559, 580, 603, 626, 650, 675, 701, 728, 755, 784, 814, 845, 877, 910, 945, 980, }
data.monsterLifeTable = { 15, 18, 21, 25, 29, 33, 38, 43, 49, 55, 61, 68, 76, 85, 94, 104, 114, 126, 138, 152, 166, 182, 199, 217, 236, 257, 280, 304, 331, 359, 389, 422, 456, 494, 534, 577, 624, 673, 726, 783, 844, 910, 980, 1055, 1135, 1221, 1313, 1411, 1516, 1629, 1749, 1878, 2015, 2162, 2319, 2486, 2665, 2857, 3061, 3279, 3512, 3760, 4025, 4308, 4610, 4932, 5276, 5642, 6033, 6449, 6894, 7367, 7872, 8410, 8984, 9595, 10246, 10940, 11679, 12466, 13304, 14198, 15149, 16161, 17240, 18388, 19610, 20911, 22296, 23770, 25338, 27007, 28784, 30673, 32684, 34823, 37098, 39519, 42093, 44831, }
data.monsterAllyLifeTable = { 15, 17, 20, 23, 26, 30, 33, 37, 41, 46, 50, 55, 60, 66, 71, 77, 84, 91, 98, 105, 113, 122, 131, 140, 150, 161, 171, 183, 195, 208, 222, 236, 251, 266, 283, 300, 318, 337, 357, 379, 401, 424, 448, 474, 501, 529, 559, 590, 622, 656, 692, 730, 769, 810, 853, 899, 946, 996, 1048, 1102, 1159, 1219, 1281, 1346, 1415, 1486, 1561, 1640, 1722, 1807, 1897, 1991, 2089, 2192, 2299, 2411, 2528, 2651, 2779, 2913, 3053, 3199, 3352, 3511, 3678, 3853, 4035, 4225, 4424, 4631, 4848, 5074, 5310, 5557, 5815, 6084, 6364, 6658, 6964, 7283, }
data.monsterDamageTable = { 5, 6, 6, 7, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 20, 21, 23, 24, 26, 28, 30, 32, 34, 36, 39, 41, 44, 47, 50, 53, 56, 59, 63, 67, 71, 75, 80, 84, 89, 94, 100, 106, 112, 118, 125, 131, 139, 147, 155, 163, 172, 181, 191, 202, 212, 224, 236, 248, 262, 275, 290, 305, 321, 338, 355, 374, 393, 413, 434, 456, 480, 504, 530, 556, 584, 614, 645, 677, 711, 746, 783, 822, 862, 905, 949, 996, 1045, 1096, 1149, 1205, 1264, 1325, 1390, 1457, 1527, 1601, 1678, 1758, }
-- from https://www.pathofexile.com/forum/view-thread/2687400, extrapolating from previous data (https://www.pathofexile.com/forum/view-thread/12056/page/492#p3321134)
-- this assumes a similar progression to evasion, and a base armour of 983 for monster level 77 (version 0.10.1) and based on the time of the post from 2013 - level 78 maps came out with version 1.0.0
-- data.monsterArmourTableOld = { 9, 11, 13, 15, 17, 19, 22, 25, 28, 31, 34, 37, 40, 43, 47, 51, 55, 59, 63, 68, 73, 78, 83, 88, 94, 100, 106, 112, 119, 126, 133, 140, 148, 156, 164, 172, 181, 190, 199, 209, 219, 230, 241, 252, 264, 276, 289, 302, 316, 330, 345, 360, 376, 392, 409, 427, 445, 464, 484, 504, 525, 547, 570, 593, 617, 642, 668, 695, 723, 752, 782, 813, 845, 878, 912, 947, 983, 1020, 1059, 1099, 1140, 1183, 1227, 1273, 1320, 1369, 1419, 1471, 1525, 1581, 1638, 1697, 1758, 1821, 1886, 1953, 2023, 2095, 2169, 2246, }
data.monsterArmourTable = { 12, 18, 26, 35, 45, 57, 73, 91, 111, 133, 157, 183, 211, 241, 279, 319, 362, 408, 457, 515, 577, 642, 711, 783, 867, 955, 1047, 1143, 1254, 1369, 1489, 1613, 1754, 1900, 2051, 2208, 2383, 2564, 2751, 2958, 3172, 3406, 3649, 3898, 4170, 4451, 4755, 5069, 5407, 5756, 6131, 6515, 6929, 7352, 7806, 8290, 8785, 9313, 9874, 10447, 11055, 11698, 12378, 13072, 13804, 14574, 15384, 16235, 17126, 18061, 19038, 20060, 21128, 22242, 23403, 24612, 25871, 27180, 28568, 30008, 31502, 33080, 34713, 36433, 38212, 40081, 42011, 44035, 46153, 48367, 50650, 53032, 55516, 58104, 60799, 63601, 66545, 69602, 72774, 76096, }
-- From MonsterVarieties.dat combined with SkillTotemVariations.dat
data.totemLifeMult = { [1] = 1.62, [2] = 1.62, [3] = 1.62, [4] = 1.62, [5] = 1.62, [6] = 2.31, [7] = 1.62, [8] = 1.94, [9] = 1.62, [10] = 1.62, [11] = 1.62, [12] = 1.62, [13] = 2.48, [15] = 2.48, [16] = 7.44, [17] = 1.94, [18] = 1.62, [19] = 1.62, }
