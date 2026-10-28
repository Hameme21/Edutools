import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class _Faculty {
  final int id;
  final String name;
  final String code;

  const _Faculty(this.id, this.name, this.code);

  String get displayName {
    final idx = name.indexOf('(');
    if (idx > 0) return name.substring(0, idx).trim();
    return name;
  }
}

class FacultyDirectorySheet extends StatefulWidget {
  const FacultyDirectorySheet({super.key});

  @override
  State<FacultyDirectorySheet> createState() => _FacultyDirectorySheetState();
}

class _FacultyDirectorySheetState extends State<FacultyDirectorySheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const _allFaculty = <_Faculty>[
    _Faculty(6992, 'A.H.M. Osama Haque (AHMOH)', 'AHMOH'),
    _Faculty(6496, 'A.K.M. Muzahidul Islam (AKMMI)', 'AKMMI'),
    _Faculty(6438, 'Abdullah Al Fahad (AAFd)', 'AAFd'),
    _Faculty(1250, 'Abdullah Al Mamun (AM)', 'AM'),
    _Faculty(7292, 'Abdullah Al-Muyeed (AbAMd)', 'AbAMd'),
    _Faculty(7073, 'Abdullah Ibne Masud Mahi (AIMM)', 'AIMM'),
    _Faculty(7333, 'Abrar Mahmood Sami (AMSa)', 'AMSa'),
    _Faculty(7180, 'Abrar Mahmud (ArMd)', 'ArMd'),
    _Faculty(6954, 'Abu Bakar Fahad (ABF)', 'ABF'),
    _Faculty(1278, 'Abu Saleh Md. Sohel-Uz-Zaman (ASSZ)', 'ASSZ'),
    _Faculty(6099, 'Abu Shafin Mohammad Mahdee Jameel (ASMMJ)', 'ASMMJ'),
    _Faculty(7245, 'Ahmed Abdullah Bin Farooqi Rayhan (AAFR)', 'AAFR'),
    _Faculty(6502, 'Ahmed Imran Kabir (AIK)', 'AIK'),
    _Faculty(7321, 'Ahmed Nesar Tahsin Choudhury (ANTC)', 'ANTC'),
    _Faculty(7270, 'Ahnaf Rafi Sharan (AhRSh)', 'AhRSh'),
    _Faculty(7156, 'Akif Hamid (AkHd)', 'AkHd'),
    _Faculty(7317, 'Al Amin Hossain (AAHn)', 'AAHn'),
    _Faculty(7052, 'Al Jamal Mustafa Shindaini (AJMSh)', 'AJMSh'),
    _Faculty(6645, 'Al-Sakib Khan Pathan (ASKP)', 'ASKP'),
    _Faculty(7320, 'Alvi Ahmed Sarker (AAS)', 'AAS'),
    _Faculty(7381, 'Amit Bin Tariqul (ABT)', 'ABT'),
    _Faculty(6670, 'Anika Tasnim Rodela (ATR)', 'ATR'),
    _Faculty(7263, 'Anindya Hoque (AnHq)', 'AnHq'),
    _Faculty(7332, 'Antara Chowdhury (ACh)', 'ACh'),
    _Faculty(7161, 'Arnab Bhattacharjee (ArBh)', 'ArBh'),
    _Faculty(6093, 'Ashek Ahmed (AkAd)', 'AkAd'),
    _Faculty(7261, 'Ashraful Islam Paran (AIP)', 'AIP'),
    _Faculty(7214, 'Asif Abrar (AsAr)', 'AsAr'),
    _Faculty(6864, 'Asif Ahmed Utsa (AAU)', 'AAU'),
    _Faculty(6910, 'Asnuva Tanvin (AsTn)', 'AsTn'),
    _Faculty(6991, 'Azizur Rahman Anik (ARnA)', 'ARnA'),
    _Faculty(1296, 'B.K.M. Mizanur Rahman (BKM)', 'BKM'),
    _Faculty(6858, 'Charles Aunkan Gomes (CAG)', 'CAG'),
    _Faculty(7232, 'Chowdhury Omar Sharif (COS)', 'COS'),
    _Faculty(6927, 'Christina Miti Rozario (ChMR)', 'ChMR'),
    _Faculty(1307, 'Dewan Md. Farid (DMF)', 'DMF'),
    _Faculty(7129, 'Didarul Islam Didar (DID)', 'DID'),
    _Faculty(4911, 'Dil  Nusrat (DN)', 'DN'),
    _Faculty(7357, 'Diniya Tahrin Bhuiyan (DTB)', 'DTB'),
    _Faculty(4882, 'Dr. Mahtab Uddin Ahmmed (MUnAd)', 'MUnAd'),
    _Faculty(7359, 'Emrul Kayes Raceme (EKR)', 'EKR'),
    _Faculty(7370, 'Erina Sharmin (ESh)', 'ESh'),
    _Faculty(7128, 'Fairoz Anika (FzAn)', 'FzAn'),
    _Faculty(6427, 'Farhan Anan Himu (FAH)', 'FAH'),
    _Faculty(7114, 'Faria Tabassum (FT)', 'FT'),
    _Faculty(7340, 'Fariha Yousuf Monia (FYM)', 'FYM'),
    _Faculty(7334, 'Fazle Rabby (FRa)', 'FRa'),
    _Faculty(7289, 'Fazlul Hoque (FHoq)', 'FHoq'),
    _Faculty(7100, 'Ferdous-Ul-Haque Joy (FHJ)', 'FHJ'),
    _Faculty(6938, 'Golam Mohammed Bhuiyan (GMB)', 'GMB'),
    _Faculty(6613, 'Gouranga Chandra Debnath (GCD)', 'GCD'),
    _Faculty(7179, 'Hafijul Hoque Chowdhury (HHCh)', 'HHCh'),
    _Faculty(6011, 'Hamidul Huq (HHq)', 'HHq'),
    _Faculty(6652, 'Hamudi Hasan Sonet (HHS)', 'HHS'),
    _Faculty(1369, 'Hasan Sarwar (HS)', 'HS'),
    _Faculty(6693, 'Hasin Anupama Azhari (HAA)', 'HAA'),
    _Faculty(1358, 'Helena Bulbul (HB)', 'HB'),
    _Faculty(7012, 'Humaira Anzum Neha (HAN)', 'HAN'),
    _Faculty(6746, 'Iftekharul Abedeen (IAb)', 'IAb'),
    _Faculty(7127, 'Imran Hossain (IHn)', 'IHn'),
    _Faculty(1371, 'Intekhab Alam (IA)', 'IA'),
    _Faculty(1380, 'Ishrat Jahan (IJ)', 'IJ'),
    _Faculty(1384, 'Ishrat Sultana (IS)', 'IS'),
    _Faculty(7308, 'Ismat Zarin (IZn)', 'IZn'),
    _Faculty(7080, 'Israt Jabin (ItJn)', 'ItJn'),
    _Faculty(6253, 'Jakowan (Jkn)', 'Jkn'),
    _Faculty(1390, 'James Bakul Sarkar (JBS)', 'JBS'),
    _Faculty(7192, 'Jamil Ahmed Joy (JAJ)', 'JAJ'),
    _Faculty(7364, 'Jannatul Ferdous Nishat (JFNt)', 'JFNt'),
    _Faculty(7086, 'Jannatun Noor Mukta (JNM)', 'JNM'),
    _Faculty(7325, 'Jarin Tasneem (JT)', 'JT'),
    _Faculty(1389, 'Jashodhan Saha (JAS)', 'JAS'),
    _Faculty(5999, 'Jerin Haque Chhanda (JHC)', 'JHC'),
    _Faculty(7230, 'Jerin Hasan Priya (JHP)', 'JHP'),
    _Faculty(7316, 'Joyonty Ghosh (JG)', 'JG'),
    _Faculty(7186, 'K M Faizullah Fuhad (KMFF)', 'KMFF'),
    _Faculty(7290, 'K Shayekh Ebne Mizan (KShEM)', 'KShEM'),
    _Faculty(7330, 'Kafi Anan (KaAn)', 'KaAn'),
    _Faculty(6972, 'Kais Zaman (KZ)', 'KZ'),
    _Faculty(1502, 'Kaled Masukur Rahman (MKMR)', 'MKMR'),
    _Faculty(7338, 'Kaspia Kabir (KKr)', 'KKr'),
    _Faculty(3805, 'Kawsar Ahmmed (KA)', 'KA'),
    _Faculty(6749, 'Kazi Abdun Noor (KAN)', 'KAN'),
    _Faculty(7147, 'Kazi Abrar Mahmud (KAM)', 'KAM'),
    _Faculty(7327, 'Kazi Fahim Tahmid (KFT)', 'KFT'),
    _Faculty(6808, 'Kazi Kamrun Nahar Tania (KKNT)', 'KKNT'),
    _Faculty(7106, 'Kazi Yousuf Hasan (KYH)', 'KYH'),
    _Faculty(7281, 'Kh Ehsanur Rahman (KhER)', 'KhER'),
    _Faculty(7219, 'Khalid Shahriar (KS)', 'KS'),
    _Faculty(1413, 'Khandoker Mahmudur Rahman (KMR)', 'KMR'),
    _Faculty(7279, 'Khandoker Makjum Wahid (KhMW)', 'KhMW'),
    _Faculty(1411, 'Khondaker Abdullah -Al-Mamun (KM)', 'KM'),
    _Faculty(6146, 'Khushnur Binte Jahangir (KBJ)', 'KBJ'),
    _Faculty(6937, 'Kirsten Gudgeon (KnGn)', 'KnGn'),
    _Faculty(7234, 'Labib Rashid Inan (LRI)', 'LRI'),
    _Faculty(7268, 'Liakat Omar Rihan (LOR)', 'LOR'),
    _Faculty(7015, 'M. Fahmin Rahman (MFRn)', 'MFRn'),
    _Faculty(1553, 'M. Rezwan Khan (MRK)', 'MRK'),
    _Faculty(7331, 'M.A. Mosabbir Antor (MAMA)', 'MAMA'),
    _Faculty(7336, 'M.M. Fahim Siddiquee (MMFS)', 'MMFS'),
    _Faculty(7371, 'M.M. Rafin Mahmud (MMRM)', 'MMRM'),
    _Faculty(7155, 'Mahbuba Sultana (MaSa)', 'MaSa'),
    _Faculty(7221, 'Mahir Amer Haque (MAmH)', 'MAmH'),
    _Faculty(7081, 'Mahmudul Hasan (MahHsn)', 'MahHsn'),
    _Faculty(1586, 'Mahtab Uddin (MUn)', 'MUn'),
    _Faculty(7280, 'Maksuda Akter (MaAkr)', 'MaAkr'),
    _Faculty(7208, 'Maliha Tasnim (MaTm)', 'MaTm'),
    _Faculty(6815, 'Mallika Datta (MD)', 'MD'),
    _Faculty(7362, 'Marjana Morshed (MMd)', 'MMd'),
    _Faculty(6563, 'Marzia Shurovi (MaShu)', 'MaShu'),
    _Faculty(6902, 'Md. Abid Hossain (AbHn)', 'AbHn'),
    _Faculty(1450, 'Md. Abu Saklayen (MASn)', 'MASn'),
    _Faculty(6939, 'Md. Aminur Islam (MdAIm)', 'MdAIm'),
    _Faculty(7372, 'Md. Anowarul Abedin (MAnAn)', 'MAnAn'),
    _Faculty(6706, 'Md. Arifur Rahman (MdArR)', 'MdArR'),
    _Faculty(6892, 'Md. Asadujjaman (MdAsn)', 'MdAsn'),
    _Faculty(1444, 'Md. Asaduzzaman (MAn)', 'MAn'),
    _Faculty(6759, 'Md. Ashadullah (MdAU)', 'MdAU'),
    _Faculty(5991, 'Md. Benzir Ahmed (MBAd)', 'MBAd'),
    _Faculty(7307, 'Md. Elias Uddin (MEUn)', 'MEUn'),
    _Faculty(6952, 'Md. Enamul Haque (MEHq)', 'MEHq'),
    _Faculty(7069, 'Md. Fayyaz Khan (MFK)', 'MFK'),
    _Faculty(7287, 'Md. Golam Hossain (MGH)', 'MGH'),
    _Faculty(6929, 'Md. Golam Mahabub Sarwar (GMS)', 'GMS'),
    _Faculty(7329, 'Md. Habibur Rahman (MdHR)', 'MdHR'),
    _Faculty(7350, 'Md. Hachhibur Rahman (MdHRn)', 'MdHRn'),
    _Faculty(6416, 'Md. Hasanuzzaman (MdHn)', 'MdHn'),
    _Faculty(7269, 'Md. Hossain Safayet (MHSt)', 'MHSt'),
    _Faculty(7291, 'Md. Intishar Rahman (MIR)', 'MIR'),
    _Faculty(1377, 'Md. Iqbal Bahar Chowdhury (IBC)', 'IBC'),
    _Faculty(7339, 'Md. Ismail Hosen (MdIH)', 'MdIH'),
    _Faculty(6065, 'Md. Jalal Uddin (MJUn)', 'MJUn'),
    _Faculty(1501, 'Md. Kaium Hossain (MKHn)', 'MKHn'),
    _Faculty(6890, 'Md. Kamrul Bari (MKB)', 'MKB'),
    _Faculty(1499, 'Md. Kamrul Hasan (MKH)', 'MKH'),
    _Faculty(7360, 'Md. Kamruzzaman (MdK)', 'MdK'),
    _Faculty(6708, 'Md. Kashedul Wahab Tuhin (KWT)', 'KWT'),
    _Faculty(6023, 'Md. Kazimul Hoque (MKHq)', 'MKHq'),
    _Faculty(7185, 'Md. Mainul Islam (MMaIm)', 'MMaIm'),
    _Faculty(7091, 'Md. Maruf Jihan Shoyeb (MJSh)', 'MJSh'),
    _Faculty(7346, 'Md. Mehedi Hasan (MdMeHn)', 'MdMeHn'),
    _Faculty(7315, 'Md. Mehedi Hasan (MMeHn)', 'MMeHn'),
    _Faculty(6965, 'Md. Minhajul Islam (MMiIm)', 'MMiIm'),
    _Faculty(7355, 'Md. Mofizur Rhaman (MMRh)', 'MMRh'),
    _Faculty(1591, 'Md. Mohan Uddin (MUd)', 'MUd'),
    _Faculty(7267, 'Md. Mostaqul Islam (MdMoIm)', 'MdMoIm'),
    _Faculty(6560, 'Md. Motaharul Islam (MdMIm)', 'MdMIm'),
    _Faculty(6977, 'Md. Moynul Islam (MoIm)', 'MoIm'),
    _Faculty(7126, 'Md. Muhaiminul Islam Nafi (MMIN)', 'MMIN'),
    _Faculty(6750, 'Md. Muhyminul Haque (MdMH)', 'MdMH'),
    _Faculty(6869, 'Md. Mujibur Rahman (MrRh)', 'MrRh'),
    _Faculty(1540, 'Md. Musharrof Hossain (MoHn)', 'MoHn'),
    _Faculty(7010, 'Md. Mushfiqul Haque Omi (MHO)', 'MHO'),
    _Faculty(6909, 'Md. Mutasim Billah Kouser (MMBK)', 'MMBK'),
    _Faculty(7363, 'Md. Nazmul Huda (MNaHu)', 'MNaHu'),
    _Faculty(7074, 'Md. Nobir Hosen (MNHn)', 'MNHn'),
    _Faculty(7058, 'Md. Nure-Alam-Dipu (NAD)', 'NAD'),
    _Faculty(6068, 'Md. Qamruzzaman (MdQ)', 'MdQ'),
    _Faculty(6696, 'Md. Romizul Islam (MdRIm)', 'MdRIm'),
    _Faculty(7099, 'Md. Saiful Islam (MSaIm)', 'MSaIm'),
    _Faculty(7210, 'Md. Saiful Islam (MSIs)', 'MSIs'),
    _Faculty(7216, 'Md. Sajjad Hossain (MSdHn)', 'MSdHn'),
    _Faculty(7375, 'Md. Salim Al Mamun (SAMn)', 'SAMn'),
    _Faculty(7342, 'Md. Sanzed Alam (SdAm)', 'SdAm'),
    _Faculty(6792, 'Md. Shadman Aadeeb (MdShA)', 'MdShA'),
    _Faculty(6859, 'Md. Shafqat Talukder (MSTR)', 'MSTR'),
    _Faculty(1664, 'Md. Shahriar Ahmed Chowdhury (SAC)', 'SAC'),
    _Faculty(1465, 'Md. Shariful Alam (MdSA)', 'MdSA'),
    _Faculty(7071, 'Md. Shohrab Hossain (MShH)', 'MShH'),
    _Faculty(7252, 'Md. Siam (MdSam)', 'MdSam'),
    _Faculty(7344, 'Md. Suzauddola (MdSu)', 'MdSu'),
    _Faculty(7345, 'Md. Taky Shaharair (MTSh)', 'MTSh'),
    _Faculty(6867, 'Md. Tanvir Raihan (MTR)', 'MTR'),
    _Faculty(6700, 'Md. Tarek Hasan (MdTH)', 'MdTH'),
    _Faculty(7235, 'Md. Zahin Alam (MZAm)', 'MZAm'),
    _Faculty(6917, 'Md. Ziaul Karim (MZK)', 'MZK'),
    _Faculty(7217, 'Md. Zunaid-Ul-Alam (MZUA)', 'MZUA'),
    _Faculty(7231, 'Miftahul Sheikh (MfSh)', 'MfSh'),
    _Faculty(1575, 'Mimnun Sultana (MSna)', 'MSna'),
    _Faculty(6156, 'Minhajul Bashir (MiBa)', 'MiBa'),
    _Faculty(7305, 'Mir Md. Fazle Rabbi (MMFR)', 'MMFR'),
    _Faculty(6668, 'Mir Moynuddin Ahmed Shibly (MMAS)', 'MMAS'),
    _Faculty(7200, 'Mobashara Islam (MobIm)', 'MobIm'),
    _Faculty(7064, 'Mobaswirul Islam (MoIsm)', 'MoIsm'),
    _Faculty(1478, 'Mofijul Hoq Masum (MHM)', 'MHM'),
    _Faculty(7286, 'Mofiz Mojib Haider (MMHr)', 'MMHr'),
    _Faculty(7165, 'Mohammad Akhtaruzzaman (MdAkh)', 'MdAkh'),
    _Faculty(1209, 'Mohammad Ali Ashraf (AAsh)', 'AAsh'),
    _Faculty(6072, 'Mohammad Amzad Hossain (MdAHn)', 'MdAHn'),
    _Faculty(1293, 'Mohammad Behroz Jalil (BJ)', 'BJ'),
    _Faculty(7189, 'Mohammad Johirul Islam (MdJI)', 'MdJI'),
    _Faculty(1451, 'Mohammad Mahboob Ali Siddiqi (MASq)', 'MASq'),
    _Faculty(7319, 'Mohammad Mahmudul Hasan Chowdhury (MMHC)', 'MMHC'),
    _Faculty(1466, 'Mohammad Mamun Elahi (ME)', 'ME'),
    _Faculty(1526, 'Mohammad Musa (MMs)', 'MMs'),
    _Faculty(1536, 'Mohammad Nurul Huda (MNH)', 'MNH'),
    _Faculty(6878, 'Mohammad Omar Farooq (MOF)', 'MOF'),
    _Faculty(6601, 'Mohammad Shahriar Rahman (MdSR)', 'MdSR'),
    _Faculty(7213, 'Mohammad Shamsul Alam Wasimi (MSAW)', 'MSAW'),
    _Faculty(7374, 'Mohammad Syful Hoque (MSHq)', 'MSHq'),
    _Faculty(1580, 'Mohammad Tariq Hasan (MTH)', 'MTH'),
    _Faculty(1774, 'Mohammad Tohidul Islam Miya (TIM)', 'TIM'),
    _Faculty(7187, 'Mohammed Jawwadul Islam (MJIm)', 'MJIm'),
    _Faculty(6709, 'Mohammed Zia Uddin (MZU)', 'MZU'),
    _Faculty(1368, 'Mohd. H. R. Joarder (HRJ)', 'HRJ'),
    _Faculty(6678, 'Mohmmad Ali (MoA)', 'MoA'),
    _Faculty(7314, 'Mohsina Rahman (MoRhn)', 'MoRhn'),
    _Faculty(7273, 'Montaha Ayub Vasha (MAV)', 'MAV'),
    _Faculty(1419, 'Mosabbir Uddin Ahmad (MA)', 'MA'),
    _Faculty(7079, 'Mosharof Hossain (MfHn)', 'MfHn'),
    _Faculty(6021, 'Muhaiminul Islam Adnan (MIA)', 'MIA'),
    _Faculty(6928, 'Muhammad Al-Amin Hoque (AAnH)', 'AAnH'),
    _Faculty(7373, 'Muhammad Amir Hossain (MdAmHn)', 'MdAmHn'),
    _Faculty(7111, 'Muhammad Anwarul Azim (MAnAm)', 'MAnAm'),
    _Faculty(1467, 'Muhammad Enamul Haque (MEH)', 'MEH'),
    _Faculty(3812, 'Muhammad Hasan Al-Mamun (MHAMn)', 'MHAMn'),
    _Faculty(6788, 'Muhammad Nomani Kabir (MNK)', 'MNK'),
    _Faculty(7312, 'Muhammad Saiful Islam (MSIsm)', 'MSIsm'),
    _Faculty(7272, 'Muhammad Sibgatullah Zunnun (MdSZ)', 'MdSZ'),
    _Faculty(7244, 'Muntasir Ahmad (MAd)', 'MAd'),
    _Faculty(6207, 'Musharrat Shabnam Shuchi (MSS)', 'MSS'),
    _Faculty(6626, 'Nabila Sabrin Sworna (NSS)', 'NSS'),
    _Faculty(6888, 'Nabila Sultana (NaSa)', 'NaSa'),
    _Faculty(7354, 'Nadiratur Rahman (NrRn)', 'NrRn'),
    _Faculty(7167, 'Nafisa Rahman (NRn)', 'NRn'),
    _Faculty(6616, 'Nafisa Tabassum (NT)', 'NT'),
    _Faculty(6669, 'Nahid Ferdous Aurna (NaFA)', 'NaFA'),
    _Faculty(6288, 'Nahid Hossain (NHn)', 'NHn'),
    _Faculty(7262, 'Nahin F. Siddiqui (NaFS)', 'NaFS'),
    _Faculty(7271, 'Naima Ansar Khan (NArKh)', 'NArKh'),
    _Faculty(4852, 'Nasrin Akter (NAr)', 'NAr'),
    _Faculty(7366, 'Nawshin Tabassum (NTm)', 'NTm'),
    _Faculty(7093, 'Nazia Shifa Mugdha (NSM)', 'NSM'),
    _Faculty(6983, 'Nazmul Hasan (NzHn)', 'NzHn'),
    _Faculty(6801, 'Nazmul Huda (NaHu)', 'NaHu'),
    _Faculty(6904, 'Nazmul Huda Mohd. Sharif Uddin (NHMS)', 'NHMS'),
    _Faculty(7176, 'Nazmun Nahar Showmi (NNS)', 'NNS'),
    _Faculty(1615, 'Nousin Laila Bristi (NLB)', 'NLB'),
    _Faculty(7178, 'Novia Nurain (NoNn)', 'NoNn'),
    _Faculty(7164, 'Nusaiba Zaman Manifa (NZMa)', 'NZMa'),
    _Faculty(3814, 'Nusrat Farzana (NFa)', 'NFa'),
    _Faculty(7094, 'Nusrath Jahan Borna (NJB)', 'NJB'),
    _Faculty(7072, 'Ohidujjaman (Ojn)', 'Ojn'),
    _Faculty(6635, 'Oliver Tirtho Sarkar (OTS)', 'OTS'),
    _Faculty(7172, 'Partha Pratim Das Roy (PPDR)', 'PPDR'),
    _Faculty(7152, 'Pranta Biswas (PB)', 'PB'),
    _Faculty(7057, 'Qazi Moinuddin Mahmud (QMMd)', 'QMMd'),
    _Faculty(6975, 'Rabeya Bakar Sarna (RBS)', 'RBS'),
    _Faculty(7162, 'Rafid Nahiyan Farabi (RNF)', 'RNF'),
    _Faculty(7020, 'Rahil Afzal Nihal (RaAN)', 'RaAN'),
    _Faculty(7227, 'Raiyan Janik Monir (RJM)', 'RJM'),
    _Faculty(7123, 'Rakibul Hasan Rafi (RaHR)', 'RaHR'),
    _Faculty(1650, 'Raqibul Mostafa (RM)', 'RM'),
    _Faculty(7361, 'Rejwan Ahmed (ReAd)', 'ReAd'),
    _Faculty(6791, 'Riasat Azim (RtAm)', 'RtAm'),
    _Faculty(7353, 'Rifa Noor (RfNr)', 'RfNr'),
    _Faculty(7153, 'Rizvan Jawad Ruhan (RJR)', 'RJR'),
    _Faculty(7358, 'Robiul Islam (RoIm)', 'RoIm'),
    _Faculty(1656, 'Rubaiya Rahtin Khan (RRK)', 'RRK'),
    _Faculty(7107, 'Rukaiya Rob (RuRb)', 'RuRb'),
    _Faculty(6558, 'Rumana Afrin (RAf)', 'RAf'),
    _Faculty(7365, 'Rusafa Islam Aurchi (RIA)', 'RIA'),
    _Faculty(1721, 'S.M. Asif-Ur-Rahman (SMAR)', 'SMAR'),
    _Faculty(6976, 'S.M. Hasibul Hassan Rizvee (HaHR)', 'HaHR'),
    _Faculty(7347, 'S.M. Kausar Parvej (SMKP)', 'SMKP'),
    _Faculty(7028, 'S.M. Rafiqul Islam (SMRI)', 'SMRI'),
    _Faculty(6593, 'Saad Hasan (SdHn)', 'SdHn'),
    _Faculty(7324, 'Sadatul lslam Sadi (SlS)', 'SlS'),
    _Faculty(6569, 'Sadia Afrin (SaAn)', 'SaAn'),
    _Faculty(6905, 'Sadia Binte Anwar (SBAr)', 'SBAr'),
    _Faculty(6646, 'Sadia Islam (SaIs)', 'SaIs'),
    _Faculty(7277, 'Sadia Islam (SaIsm)', 'SaIsm'),
    _Faculty(7367, 'Sadia Zaman (SZn)', 'SZn'),
    _Faculty(1686, 'Sadid Muneer (SdM)', 'SdM'),
    _Faculty(6704, 'Sagar Dutta (SaDa)', 'SaDa'),
    _Faculty(7000, 'Sahid Hossain Mustakim (SHMm)', 'SHMm'),
    _Faculty(7018, 'Saidul Islam (SIsm)', 'SIsm'),
    _Faculty(7182, 'Saifullah Mahbub (SaMb)', 'SaMb'),
    _Faculty(7376, 'Saima Ansar Jui (SAJ)', 'SAJ'),
    _Faculty(1667, 'Saima Hasin (SaHn)', 'SaHn'),
    _Faculty(7110, 'Sajid Ahmed Chowdhury (SdACh)', 'SdACh'),
    _Faculty(7197, 'Sajjad Ahmed (SdAh)', 'SdAh'),
    _Faculty(7311, 'Sajjad Hossain (SaHsn)', 'SaHsn'),
    _Faculty(7341, 'Sakibul Satter Shupto (SaSSh)', 'SaSSh'),
    _Faculty(6711, 'Salma Begum (SaB)', 'SaB'),
    _Faculty(1711, 'Salma Karim (SKa)', 'SKa'),
    _Faculty(6702, 'Samin Sharaf Somik (SSSk)', 'SSSk'),
    _Faculty(7265, 'Saqif Kaisar (SaKar)', 'SaKar'),
    _Faculty(1739, 'Sarker Rafij Ahmed Ratan (SRA)', 'SRA'),
    _Faculty(7382, 'Sarwat Amin (StA)', 'StA'),
    _Faculty(6094, 'Sayeda Chandra Tabassum (SCT)', 'SCT'),
    _Faculty(7228, 'Sayeem Been Zaman (SBZ)', 'SBZ'),
    _Faculty(7177, 'Sayem Shahad (SmSd)', 'SmSd'),
    _Faculty(6208, 'Seyama Sultana (SeyS)', 'SeyS'),
    _Faculty(7309, 'Shafqat Chaudhuri (SCh)', 'SCh'),
    _Faculty(6960, 'Shahil Yasar Haque (SYH)', 'SYH'),
    _Faculty(7163, 'Shahriar Mahmud (ShMd)', 'ShMd'),
    _Faculty(7159, 'Shahriare Mahmud Sakib (ShMS)', 'ShMS'),
    _Faculty(7337, 'Shaila Ahsan (ShAhn)', 'ShAhn'),
    _Faculty(1694, 'Shakila Aziz (ShAz)', 'ShAz'),
    _Faculty(6598, 'Shantanu Kumar Saha (SKS)', 'SKS'),
    _Faculty(6811, 'Sharif Ahmed Mukul (ShAM)', 'ShAM'),
    _Faculty(1710, 'Shayla Khanam (SK)', 'SK'),
    _Faculty(6778, 'Sheikh Mohammad Shafiul Islam (SMSI)', 'SMSI'),
    _Faculty(7326, 'Sheikh Mohammed Al Hadi Elaf (SMAHE)', 'SMAHE'),
    _Faculty(7060, 'Shekh. Md. Saifur Rahman (SMSR)', 'SMSR'),
    _Faculty(7063, 'Sherajul Arifin (ShArn)', 'ShArn'),
    _Faculty(7061, 'Shihab Ahmed (ShAhd)', 'ShAhd'),
    _Faculty(7243, 'Shishir Shahriar Arif (SSAf)', 'SSAf'),
    _Faculty(6600, 'Shoaib Ahmed (SbAd)', 'SbAd'),
    _Faculty(6426, 'Shoib Ahmed Shourav (SAhSh)', 'SAhSh'),
    _Faculty(7056, 'Shuva Ghosh (ShGh)', 'ShGh'),
    _Faculty(7218, 'Siana Rizwan (SnRn)', 'SnRn'),
    _Faculty(4878, 'Siddique Md. Lutful Kabir (SMLK)', 'SMLK'),
    _Faculty(6868, 'Sidratul Muntaha (SiMa)', 'SiMa'),
    _Faculty(7062, 'Sidratul Tanzila Tasmi (STT)', 'STT'),
    _Faculty(7369, 'Sudipto Mondal (SuMo)', 'SuMo'),
    _Faculty(7335, 'Sumaiya Tarannum (SuT)', 'SuT'),
    _Faculty(1661, 'Suman Ahmmed (SA)', 'SA'),
    _Faculty(7008, 'Sumia Zahid (SZ)', 'SZ'),
    _Faculty(7264, 'Syed Abu Ammar Muhammad Zarif (SAMZ)', 'SAMZ'),
    _Faculty(7157, 'Syed Moktacim Billah (SMB)', 'SMB'),
    _Faculty(7266, 'Syed Samin Sadaf (SSSf)', 'SSSf'),
    _Faculty(7229, 'Tahia Hossain (TaH)', 'TaH'),
    _Faculty(6973, 'Tahmid Mosaddeque (TaMo)', 'TaMo'),
    _Faculty(6874, 'Taki Yashir (TY)', 'TY'),
    _Faculty(6911, 'Taniah Mahmuda Tinni (TMT)', 'TMT'),
    _Faculty(7011, 'Tanmoy Bipro Das (TBD)', 'TBD'),
    _Faculty(6783, 'Tanseer Ahamed (TrAd)', 'TrAd'),
    _Faculty(7318, 'Tanveer Ahmed Khan Fahim (TAKF)', 'TAKF'),
    _Faculty(6256, 'Tanzila Amir (TaA)', 'TaA'),
    _Faculty(7351, 'Tariq Bin Yousuf (TBY)', 'TBY'),
    _Faculty(7246, 'Tashrifa Fairuz (TaFz)', 'TaFz'),
    _Faculty(7323, 'Tasinul Islam Ahon (TIA)', 'TIA'),
    _Faculty(7150, 'Tasmia Binte Sogir (TBS)', 'TBS'),
    _Faculty(6974, 'Tasmin Sanjida (TaSa)', 'TaSa'),
    _Faculty(6784, 'Tasneem Jahan Tumpa (TJT)', 'TJT'),
    _Faculty(7348, 'Tasriad Ahmed Tias (TATs)', 'TATs'),
    _Faculty(7276, 'Torun Haldar (THr)', 'THr'),
    _Faculty(6845, 'Umama Rahman (UR)', 'UR'),
    _Faculty(7009, 'Umme Ammara (UA)', 'UA'),
    _Faculty(7233, 'Umme Habiba (UmH)', 'UmH'),
    _Faculty(7328, 'Zaara Zabeen Arpa (ZZA)', 'ZZA'),
    _Faculty(7368, 'Zakia Tabassum (ZT)', 'ZT'),
    _Faculty(7322, 'Zia Ul Hassan Abdullah (ZUHA)', 'ZUHA'),
    _Faculty(1801, 'Zinnatun Nesa (ZN)', 'ZN'),
    _Faculty(7356, 'Zobaer Ibn Razzaque (ZIR)', 'ZIR'),
    _Faculty(7352, 'Zolakha Akter Shifa (ZAS)', 'ZAS'),
  ];

  List<_Faculty> get _filtered {
    if (_query.isEmpty) return _allFaculty;
    final q = _query.toLowerCase();
    return _allFaculty.where((f) =>
      f.name.toLowerCase().contains(q) ||
      f.code.toLowerCase().contains(q)
    ).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final results = _filtered;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0x1A10B981),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.people_rounded, color: AppTheme.accentColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Faculty Directory',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${_allFaculty.length} UIU Faculty Members',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _query = val.trim()),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search by name or code...',
                hintStyle: TextStyle(color: isDark ? Colors.white30 : const Color(0xFFCBD5E1)),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _query.isEmpty ? 'All Faculty' : '${results.length} result${results.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          Flexible(
            child: results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'No faculty found',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try a different name or code',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                    itemCount: results.length,
                    itemBuilder: (ctx, index) {
                      final f = results[index];
                      final letter = f.displayName.isNotEmpty
                          ? f.displayName[0].toUpperCase()
                          : '?';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.accentColor.withValues(alpha: 0.15),
                          child: Text(
                            letter,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.accentColor,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        title: Text(
                          f.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        subtitle: Container(
                          margin: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  f.code,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Text(
                          '#${f.id}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                          ),
                        ),
                        visualDensity: const VisualDensity(vertical: -1),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
