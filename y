local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local LocalPlayer       = Players.LocalPlayer

-- WINDUI
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

-- REMOTES
local Remotes         = ReplicatedStorage:WaitForChild("Remotes", 15)
local R_SubmitWord    = Remotes:WaitForChild("SubmitWord", 10)
local R_TypeSound     = Remotes:FindFirstChild("TypeSound")
local R_UsedWordWarn  = Remotes:FindFirstChild("UsedWordWarn")
local R_PlayerCorrect = Remotes:FindFirstChild("PlayerCorrect")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KBBI
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local WordSet    = {}
local ByLetter   = {}
local kbbiLoaded = false
local kbbiStatus = "Loading..."
local totalWords = 0

local function addWord(w)
    w = w:lower():gsub("[^a-z]","")
    if #w < 2 or WordSet[w] then return end
    WordSet[w] = true
    local fl = w:sub(1,1)
    if not ByLetter[fl] then ByLetter[fl] = {} end
    table.insert(ByLetter[fl], w)
end

local function getRarityText()
    local data = {}
    for i = string.byte("a"), string.byte("z") do
        local ch = string.char(i)
        table.insert(data, {l=ch, n=ByLetter[ch] and #ByLetter[ch] or 0})
    end
    table.sort(data, function(a,b) return a.n < b.n end)
    local lines = {}
    for _, d in ipairs(data) do
        if d.n > 0 then table.insert(lines, d.l:upper()..": "..d.n) end
    end
    return table.concat(lines, "  ")
end

local ParaDB, ParaStatus, ParaRarity  -- forward

-- HARD WORDS: embedded langsung (2559 kata susah, tidak butuh HttpGet kedua)
local HardWords={
    ["abasia"]=1,["abelia"]=1,["abetalipoproteinemia"]=1,["abibliofobia"]=1,["abisinia"]=1,["ablepsia"]=1,["ablutofilia"]=1,["ablutofobia"]=1,["ablutomania"]=1,["abrosia"]=1,
    ["abstinensia"]=1,["abulia"]=1,["acacia"]=1,["acidemia"]=1,["acintia"]=1,["aclisia"]=1,["acronychia"]=1,["actinaria"]=1,["adenia"]=1,["adermatoglifia"]=1,
    ["adikia"]=1,["adimanusia"]=1,["adinamia"]=1,["adipsia"]=1,["adisatria"]=1,["aditia"]=1,["adiwidia"]=1,["adularia"]=1,["adventisia"]=1,["adverbia"]=1,
    ["aerofagia"]=1,["aerofobia"]=1,["aeronausifobia"]=1,["aeroterapia"]=1,["afagia"]=1,["afakia"]=1,["afantasia"]=1,["afasia"]=1,["afemia"]=1,["afenfosmefobia"]=1,
    ["afibrinogenemia"]=1,["afonia"]=1,["afrasia"]=1,["agalaksia"]=1,["ageusia"]=1,["agiria"]=1,["agirofobia"]=1,["aglaia"]=1,["agliofobia"]=1,["agnosia"]=1,
    ["agonia"]=1,["agorafobia"]=1,["agrafestesia"]=1,["agrafia"]=1,["agrafobia"]=1,["agraria"]=1,["agripnia"]=1,["agrizoofobia"]=1,["agrokimia"]=1,["agromania"]=1,
    ["ahalmatofilia"]=1,["ahilognosia"]=1,["ahilogsonia"]=1,["aibohfobia"]=1,["aikmofobia"]=1,["ailurofilia"]=1,["ailurofobia"]=1,["aisibia"]=1,["akademia"]=1,["akalasia"]=1,
    ["akapnia"]=1,["akarofobia"]=1,["akasia"]=1,["akatalasemia"]=1,["akatalepsia"]=1,["akinesia"]=1,["akinetopsia"]=1,["aklasia"]=1,["aklorhidria"]=1,["akluofobia"]=1,
    ["akondroplasia"]=1,["akrasia"]=1,["akrodinia"]=1,["akrofobia"]=1,["akromania"]=1,["akromatopsia"]=1,["akroparaestesia"]=1,["akrotomorfilia"]=1,["aktinokimia"]=1,["aktuaria"]=1,
    ["alaestesia"]=1,["alalia"]=1,["albania"]=1,["albizzia"]=1,["albuminuria"]=1,["albuminurofobia"]=1,["aleksia"]=1,["alektorofobia"]=1,["alelokimia"]=1,["algesia"]=1,
    ["algofobia"]=1,["alia"]=1,["aliumfobia"]=1,["alkalemia"]=1,["alkimia"]=1,["alocasia"]=1,["alodinia"]=1,["alodoksafobia"]=1,["alogia"]=1,["alogotrofia"]=1,
    ["aloksenia"]=1,["alopesia"]=1,["alpinia"]=1,["alsodeia"]=1,["alstonia"]=1,["altingia"]=1,["alwasia"]=1,["alyxia"]=1,["amaksofobia"]=1,["amatofobia"]=1,
    ["ambligeustia"]=1,["amblikusia"]=1,["ambliobia"]=1,["ambliopia"]=1,["ambrosia"]=1,["ametria"]=1,["ametropia"]=1,["amikofobia"]=1,["amilemia"]=1,["aminoasiduria"]=1,
    ["amiotonia"]=1,["amnesia"]=1,["amofilia"]=1,["amonia"]=1,["amorfognosia"]=1,["ampullaria"]=1,["anabelfobia"]=1,["anaemia"]=1,["anaesthesia"]=1,["anakia"]=1,
    ["analgesia"]=1,["anaria"]=1,["anatidaefobia"]=1,["anatolia"]=1,["anbia"]=1,["androfilia"]=1,["androfobia"]=1,["anemia"]=1,["anemofobia"]=1,["anestesia"]=1,
    ["angelesia"]=1,["angelisia"]=1,["anginofobia"]=1,["anglofilia"]=1,["anglofobia"]=1,["angrofobia"]=1,["angustifolia"]=1,["anhedonia"]=1,["aniridia"]=1,["aniscia"]=1,
    ["aniseikonia"]=1,["anisokoria"]=1,["ankraofobia"]=1,["anodonsia"]=1,["anoksemia"]=1,["anoksia"]=1,["anopsia"]=1,["anoreksia"]=1,["anorgasmia"]=1,["anortopia"]=1,
    ["anortopsia"]=1,["anosmia"]=1,["antarmanusia"]=1,["antarpria"]=1,["antianemia"]=1,["antiaritmia"]=1,["antimalaria"]=1,["antlia"]=1,["antlofobia"]=1,["antofilia"]=1,
    ["antofobia"]=1,["antomania"]=1,["antrofobia"]=1,["antropofobia"]=1,["anuptafobia"]=1,["anuria"]=1,["apastia"]=1,["apeirofobia"]=1,["apifobia"]=1,["apimania"]=1,
    ["aplasia"]=1,["apodisofilia"]=1,["apologia"]=1,["apopleksia"]=1,["apoplexia"]=1,["aporia"]=1,["aposia"]=1,["apositia"]=1,["apraksia"]=1,["apunsia"]=1,
    ["aquilaria"]=1,["arabia"]=1,["araknofobia"]=1,["aralia"]=1,["ardisia"]=1,["argiria"]=1,["aria"]=1,["aridifolia"]=1,["aritmia"]=1,["aritmofobia"]=1,
    ["armenia"]=1,["armeria"]=1,["arsonfobia"]=1,["artemia"]=1,["artemisia"]=1,["artia"]=1,["artralgia"]=1,["asetonemia"]=1,["asetonuria"]=1,["asfiksia"]=1,
    ["asfiksofilia"]=1,["asia"]=1,["asiafilia"]=1,["asidaminuria"]=1,["asidosia"]=1,["astasia"]=1,["astenia"]=1,["astenofobia"]=1,["astenopia"]=1,["astrafobia"]=1,
    ["astrofilia"]=1,["astrofobia"]=1,["ataksia"]=1,["ataksofobia"]=1,["atazagorafobia"]=1,["atelofobia"]=1,["atheresia"]=1,["atikifobia"]=1,["atomosofobia"]=1,["atresia"]=1,
    ["audiofilia"]=1,["aulia"]=1,["aulofobia"]=1,["aurantifolia"]=1,["auratifolia"]=1,["auricularia"]=1,["auriculiformia"]=1,["aurikularia"]=1,["aurofobia"]=1,["australia"]=1,
    ["austria"]=1,["austronesia"]=1,["autodisomofobia"]=1,["autofobia"]=1,["automatonofobia"]=1,["automisofobia"]=1,["aviatofobia"]=1,["avicennia"]=1,["aviofobia"]=1,["azoospermia"]=1,
    ["azotemia"]=1,["babesia"]=1,["babilonia"]=1,["badia"]=1,["bahagia"]=1,["bakpia"]=1,["bakteremia"]=1,["bakteriofobia"]=1,["bakteriuria"]=1,["balistofobia"]=1,
    ["bankdunia"]=1,["barbaria"]=1,["barleria"]=1,["barofobia"]=1,["barringtomia"]=1,["barringtonia"]=1,["bartramia"]=1,["basifobia"]=1,["batavia"]=1,["batmofobia"]=1,
    ["batofobia"]=1,["batrakofobia"]=1,["batumulia"]=1,["bauhinia"]=1,["baukimia"]=1,["begonia"]=1,["belarusia"]=1,["belgia"]=1,["belia"]=1,["belonefobia"]=1,
    ["bengalensia"]=1,["berahasia"]=1,["berbahagia"]=1,["berdunia"]=1,["beria"]=1,["berkriteria"]=1,["bermanusia"]=1,["bernostalgia"]=1,["bernumeralia"]=1,["bersedia"]=1,
    ["bersetia"]=1,["bersia"]=1,["bersukaria"]=1,["berusia"]=1,["bia"]=1,["bibliofilia"]=1,["bibliofobia"]=1,["bibliomania"]=1,["bigardia"]=1,["bigoreksia"]=1,
    ["biogeokimia"]=1,["biokimia"]=1,["bischofia"]=1,["bkia"]=1,["blattaria"]=1,["blenofobia"]=1,["bochmeria"]=1,["boehmeria"]=1,["bohemia"]=1,["bohsia"]=1,
    ["bolivia"]=1,["borneensia"]=1,["borreria"]=1,["bosnia"]=1,["botanofobia"]=1,["botia"]=1,["bradikardia"]=1,["brasilia"]=1,["breksia"]=1,["bria"]=1,
    ["bridelia"]=1,["britania"]=1,["bromidrosifobia"]=1,["brontofobia"]=1,["buchanania"]=1,["buchaninia"]=1,["bufonofobia"]=1,["bulgaria"]=1,["bulimia"]=1,["cachexia"]=1,
    ["caesalpinia"]=1,["caesia"]=1,["cafetaria"]=1,["calapparia"]=1,["camelia"]=1,["camellia"]=1,["canavalia"]=1,["canavilia"]=1,["carrallia"]=1,["cassia"]=1,
    ["ceimafobia"]=1,["cekoslowakia"]=1,["celebia"]=1,["celosia"]=1,["cendekia"]=1,["cendikia"]=1,["cereria"]=1,["ceria"]=1,["ceteria"]=1,["chailettia"]=1,
    ["challattia"]=1,["champeria"]=1,["charantia"]=1,["cia"]=1,["citrifolia"]=1,["clitoria"]=1,["coelostegia"]=1,["collacalia"]=1,["colocasia"]=1,["comifolia"]=1,
    ["commersonia"]=1,["cordia"]=1,["crescentia"]=1,["crotalaria"]=1,["crypteronia"]=1,["cudrania"]=1,["cunia"]=1,["dadia"]=1,["dahlia"]=1,["daitia"]=1,
    ["dalbergia"]=1,["daria"]=1,["dekstrofobia"]=1,["delliaia"]=1,["demensia"]=1,["demofobia"]=1,["dendrofilia"]=1,["dendrofobia"]=1,["dentofobia"]=1,["deria"]=1,
    ["dermatofobia"]=1,["desmoplasia"]=1,["detia"]=1,["deutranomalopia"]=1,["deutranopia"]=1,["dia"]=1,["diabetofobia"]=1,["diakonia"]=1,["didaskaleinofobia"]=1,["diglosia"]=1,
    ["dikarunia"]=1,["dikefobia"]=1,["dillenia"]=1,["dimensia"]=1,["dinofobia"]=1,["diplofobia"]=1,["dipsomania"]=1,["dirazia"]=1,["disania"]=1,["disastria"]=1,
    ["disdiadokokinesia"]=1,["diselia"]=1,["disfagia"]=1,["disfonia"]=1,["disforia"]=1,["disgrafia"]=1,["dishabilifobia"]=1,["dishidria"]=1,["disia"]=1,["diskomania"]=1,
    ["dislalia"]=1,["disleksia"]=1,["dislipidemia"]=1,["dismorfia"]=1,["dismorfofobia"]=1,["disnomia"]=1,["disolventia"]=1,["disoreksia"]=1,["dispareunia"]=1,["dispepsia"]=1,
    ["displasia"]=1,["disprosodia"]=1,["disritmia"]=1,["distikifobia"]=1,["distimia"]=1,["distokia"]=1,["distopia"]=1,["distosia"]=1,["disuria"]=1,["diterania"]=1,
    ["doksofobia"]=1,["domatofobia"]=1,["dria"]=1,["dromomania"]=1,["drynaria"]=1,["dukaria"]=1,["dunia"]=1,["duria"]=1,["efebifobia"]=1,["efebofilia"]=1,
    ["eforia"]=1,["egomania"]=1,["eichornia"]=1,["eisoptrofobia"]=1,["eklamsia"]=1,["eklesiofobia"]=1,["ekofobia"]=1,["ekofraksia"]=1,["ekofrasia"]=1,["ekokinesia"]=1,
    ["ekolalia"]=1,["ekomania"]=1,["ekopraksia"]=1,["ekornia"]=1,["eksofasia"]=1,["eksoftalmia"]=1,["eksoptalmia"]=1,["ekuinofobia"]=1,["elektrofobia"]=1,["elektrokimia"]=1,
    ["elettaria"]=1,["eleuterofobia"]=1,["ellipeia"]=1,["elurofobia"]=1,["embelia"]=1,["embolalia"]=1,["emetofobia"]=1,["endivia"]=1,["endofasia"]=1,["endokardia"]=1,
    ["enetofobia"]=1,["enofobia"]=1,["enosiofobia"]=1,["ensifolia"]=1,["ensiklopedia"]=1,["entomofobia"]=1,["eosofobia"]=1,["epistaksiofobia"]=1,["epistemofobia"]=1,["epistolofobia"]=1,
    ["eqnisetifolia"]=1,["equiaetifolia"]=1,["equisetifolia"]=1,["equsetifolia"]=1,["ereutrofobia"]=1,["ergasiofobia"]=1,["ergofobia"]=1,["eritrofobia"]=1,["eritroplakia"]=1,["ermitofobia"]=1,
    ["erotofobia"]=1,["ervatamia"]=1,["escherichia"]=1,["eslandia"]=1,["estesia"]=1,["estonia"]=1,["etiopia"]=1,["eufobia"]=1,["euforbia"]=1,["euforia"]=1,
    ["eugenia"]=1,["eulia"]=1,["euphorbia"]=1,["euphoria"]=1,["eurasia"]=1,["eurotofobia"]=1,["eustachia"]=1,["eutanasia"]=1,["eutosia"]=1,["excoecaria"]=1,
    ["eximia"]=1,["exocecaria"]=1,["exoecaria"]=1,["facia"]=1,["fagofobia"]=1,["fagomania"]=1,["falakrofobia"]=1,["falia"]=1,["falofobia"]=1,["familia"]=1,
    ["fantosmia"]=1,["farmakofobia"]=1,["fasia"]=1,["fasmofobia"]=1,["febrifobia"]=1,["felinofobia"]=1,["fengofobia"]=1,["fenilketonuria"]=1,["ferumfobia"]=1,["fia"]=1,
    ["fibromialgia"]=1,["fidusia"]=1,["filaria"]=1,["filemafobia"]=1,["filodia"]=1,["filofobia"]=1,["filokladia"]=1,["filosofobia"]=1,["fimbria"]=1,["finlandia"]=1,
    ["fitokimia"]=1,["flacourtia"]=1,["flagellaria"]=1,["flueggia"]=1,["fobia"]=1,["fobofobia"]=1,["fokasia"]=1,["fomofobia"]=1,["fonofobia"]=1,["fordonia"]=1,
    ["fotoaugliafobia"]=1,["fotofobia"]=1,["fotokimia"]=1,["fotopsia"]=1,["fragaria"]=1,["framboesia"]=1,["frambusia"]=1,["frankofobia"]=1,["freycinetia"]=1,["frigofobia"]=1,
    ["fusia"]=1,["galaktosemia"]=1,["galaktosuria"]=1,["galeofobia"]=1,["galisia"]=1,["galomania"]=1,["gambia"]=1,["gamofobia"]=1,["gandaria"]=1,["garcinia"]=1,
    ["gardenia"]=1,["gefirofobia"]=1,["geliofobia"]=1,["geniofobia"]=1,["genitalia"]=1,["genufobia"]=1,["geofagia"]=1,["geokimia"]=1,["geopelia"]=1,["georgia"]=1,
    ["geraskofobia"]=1,["geria"]=1,["germafobia"]=1,["germanofobia"]=1,["gerontofobia"]=1,["gia"]=1,["ginefobia"]=1,["ginekomastia"]=1,["ginofobia"]=1,["gleichemia"]=1,
    ["gleichenia"]=1,["glikemia"]=1,["glikosuria"]=1,["globofobia"]=1,["glosofobia"]=1,["glosolalia"]=1,["glukosuria"]=1,["gomania"]=1,["gonia"]=1,["gramedia"]=1,
    ["gratia"]=1,["greenia"]=1,["grewia"]=1,["griffithia"]=1,["griffithiia"]=1,["grotalaria"]=1,["hadefobia"]=1,["haemaria"]=1,["haematuria"]=1,["hafefobia"]=1,
    ["halia"]=1,["hamartofobia"]=1,["haptofobia"]=1,["harpaksofobia"]=1,["hebefilia"]=1,["hebefrenia"]=1,["hedonofobia"]=1,["heksakosioiheksekontaheksafobia"]=1,["helikonia"]=1,["heliofilia"]=1,
    ["heliofobia"]=1,["helmintofobia"]=1,["hemafobia"]=1,["hematofobia"]=1,["hematokezia"]=1,["hemiplegia"]=1,["hemofilia"]=1,["hemofobia"]=1,["hemolakria"]=1,["hemospermia"]=1,
    ["hernia"]=1,["herpetofobia"]=1,["heterofobia"]=1,["heterokromia"]=1,["hia"]=1,["hidrofilia"]=1,["hidrofobia"]=1,["hidrologia"]=1,["hielofobia"]=1,["hierofobia"]=1,
    ["higlokemia"]=1,["higrofilia"]=1,["higrofobia"]=1,["hilefobia"]=1,["hilofobia"]=1,["hindia"]=1,["hipegiafobia"]=1,["hiperamonemia"]=1,["hiperbilirubinemia"]=1,["hiperemia"]=1,
    ["hiperestesia"]=1,["hiperfosfatemia"]=1,["hiperglikemia"]=1,["hiperglisemia"]=1,["hiperinsulinemia"]=1,["hiperkalemia"]=1,["hiperkalsemia"]=1,["hiperkalsiuria"]=1,["hiperkapnia"]=1,["hiperklorhidria"]=1,
    ["hiperkolesterolemia"]=1,["hiperlipemia"]=1,["hiperlipidemia"]=1,["hipermedia"]=1,["hipermetropia"]=1,["hiperoksemia"]=1,["hiperopia"]=1,["hiperosmia"]=1,["hiperplasia"]=1,["hiperprolaktinemia"]=1,
    ["hipersomnia"]=1,["hipertermia"]=1,["hipertrigliseridemia"]=1,["hiperurisemia"]=1,["hipervolemia"]=1,["hipnofobia"]=1,["hipochondria"]=1,["hipofilia"]=1,["hipofobia"]=1,["hipofosfatemia"]=1,
    ["hipofremia"]=1,["hipogesia"]=1,["hipoglikemia"]=1,["hipoglisemia"]=1,["hipokalemia"]=1,["hipokalsemia"]=1,["hipokinesia"]=1,["hipoklorhidria"]=1,["hipokondria"]=1,["hipoksemia"]=1,
    ["hipoksia"]=1,["hipomania"]=1,["hipomastia"]=1,["hipomnesia"]=1,["hiponatremia"]=1,["hipoplasia"]=1,["hipoproteinemia"]=1,["hipospadia"]=1,["hipotermia"]=1,["hipovolemia"]=1,
    ["hipsifobia"]=1,["hirsutofilia"]=1,["histeria"]=1,["histokimia"]=1,["hobofobia"]=1,["hodofobia"]=1,["holothusia"]=1,["homiklofobia"]=1,["homilofobia"]=1,["homofilia"]=1,
    ["homofobia"]=1,["hongaria"]=1,["hoplofilia"]=1,["hoplofobia"]=1,["hormefobia"]=1,["hrivnia"]=1,["hungaria"]=1,["huria"]=1,["ia"]=1,["iatrofobia"]=1,
    ["ideofobia"]=1,["ikonia"]=1,["ikonofobia"]=1,["iktiofobia"]=1,["ilicifolia"]=1,["ilingofobia"]=1,["ilopasia"]=1,["impersonalia"]=1,["imunokimia"]=1,["imunositokimia"]=1,
    ["india"]=1,["indonesia"]=1,["indria"]=1,["inersia"]=1,["inertia"]=1,["inkontinensia"]=1,["insektofobia"]=1,["insomnia"]=1,["instrumentalia"]=1,["insulafobia"]=1,
    ["inteligensia"]=1,["intermedia"]=1,["intsia"]=1,["inuria"]=1,["iofobia"]=1,["irlandia"]=1,["irvingia"]=1,["iskemia"]=1,["islamofobia"]=1,["islandia"]=1,
    ["isopterofobia"]=1,["italia"]=1,["itifalofobia"]=1,["jackia"]=1,["jalabria"]=1,["jasmania"]=1,["jordania"]=1,["justicia"]=1,["kaempferia"]=1,["kaetofobia"]=1,
    ["kafetaria"]=1,["kafeteria"]=1,["kainofobia"]=1,["kakeksia"]=1,["kakofobia"]=1,["kakofonofilia"]=1,["kalapia"]=1,["kaledonia"]=1,["kalifornia"]=1,["kaliginefobia"]=1,
    ["kamelia"]=1,["kamsia"]=1,["kania"]=1,["kanofilia"]=1,["kanserofobia"]=1,["karbofobia"]=1,["kardia"]=1,["karfasia"]=1,["karia"]=1,["karibia"]=1,
    ["karnofobia"]=1,["karthalsia"]=1,["karunia"]=1,["kasia"]=1,["kasiopeia"]=1,["kassia"]=1,["katagelofobia"]=1,["katapedafobia"]=1,["katatonia"]=1,["katoptrofobia"]=1,
    ["katsaridafobia"]=1,["kenofobia"]=1,["keratomalasia"]=1,["keraunofobia"]=1,["kerofobia"]=1,["kesatria"]=1,["kesia"]=1,["ketonemia"]=1,["ketonuria"]=1,["kia"]=1,
    ["kimia"]=1,["kinestesia"]=1,["kinetofobia"]=1,["kinofobia"]=1,["kionofobia"]=1,["kiraptofobia"]=1,["kirghizia"]=1,["kiropterofilia"]=1,["kladodia"]=1,["klaustrofobia"]=1,
    ["kleinhovia"]=1,["kleitrofobia"]=1,["kleptofobia"]=1,["kleptomania"]=1,["klismafilia"]=1,["klitrofobia"]=1,["klorofobia"]=1,["knidofobia"]=1,["kofraksia"]=1,["koimetrofobia"]=1,
    ["koinonifobia"]=1,["koitofobia"]=1,["koksidia"]=1,["kolalia"]=1,["kolemia"]=1,["kolerofobia"]=1,["kolesterolfobia"]=1,["kolombia"]=1,["kolpofobia"]=1,["kolumbia"]=1,
    ["komedia"]=1,["kometofobia"]=1,["komputerfobia"]=1,["komunistofobia"]=1,["koompassia"]=1,["kopofobia"]=1,["koprafagia"]=1,["kopraksia"]=1,["koprofilia"]=1,["koprofobia"]=1,
    ["koprolalia"]=1,["korintia"]=1,["kornia"]=1,["kornukopia"]=1,["korofilia"]=1,["korthalsia"]=1,["kosmikofobia"]=1,["koulrofobia"]=1,["koumpounofobia"]=1,["kriofobia"]=1,
    ["krisofilia"]=1,["krisofobia"]=1,["kristalofobia"]=1,["kristofobia"]=1,["kriteria"]=1,["kroasia"]=1,["kroatia"]=1,["kromofobia"]=1,["kronofobia"]=1,["kronomentrofobia"]=1,
    ["ksatria"]=1,["kuria"]=1,["kurnia"]=1,["kurrimia"]=1,["labia"]=1,["labisia"]=1,["lagenaria"]=1,["lakahia"]=1,["lakanofobia"]=1,["laliofobia"]=1,
    ["lancia"]=1,["langcia"]=1,["langerstroemia"]=1,["lankolia"]=1,["lansia"]=1,["lasia"]=1,["lasinia"]=1,["latifolia"]=1,["latopia"]=1,["latvia"]=1,
    ["laurifolia"]=1,["lautanhindia"]=1,["lautkaribia"]=1,["lautmediterania"]=1,["lavakultofilia"]=1,["lavenia"]=1,["lawsonia"]=1,["leersia"]=1,["lekemia"]=1,["leksikonofilia"]=1,
    ["lesia"]=1,["lettsomia"]=1,["leucobalia"]=1,["leukemia"]=1,["leukimia"]=1,["leukofobia"]=1,["leukonisia"]=1,["leukopenia"]=1,["leukoplakia"]=1,["lia"]=1,
    ["liberia"]=1,["libia"]=1,["licia"]=1,["ligofilia"]=1,["lilapsofobia"]=1,["limfopenia"]=1,["limfositopenia"]=1,["limnofobia"]=1,["lipemia"]=1,["lipidemia"]=1,
    ["listeria"]=1,["lithuania"]=1,["litofilia"]=1,["lituania"]=1,["logofilia"]=1,["logofobia"]=1,["logopedia"]=1,["lokia"]=1,["lokiofobia"]=1,["longifolia"]=1,
    ["lonomia"]=1,["lumpia"]=1,["luscinia"]=1,["lusia"]=1,["lutrafobia"]=1,["macrophygia"]=1,["madia"]=1,["mafia"]=1,["mageirokofobia"]=1,["magnesia"]=1,
    ["magnetokimia"]=1,["mahamulia"]=1,["mahia"]=1,["maiesiofilia"]=1,["makadamia"]=1,["makedonia"]=1,["makroglosia"]=1,["makrokimia"]=1,["makromania"]=1,["makromelia"]=1,
    ["makrosomia"]=1,["makroxenoglosofobia"]=1,["maksomania"]=1,["malaria"]=1,["malasia"]=1,["malaysia"]=1,["malesia"]=1,["mamalia"]=1,["mania"]=1,["maniafobia"]=1,
    ["manusia"]=1,["maria"]=1,["marsdenia"]=1,["marsedenia"]=1,["marumia"]=1,["masambia"]=1,["massoia"]=1,["mastalgia"]=1,["mastigofobia"]=1,["matofobia"]=1,
    ["mauritania"]=1,["medangsia"]=1,["media"]=1,["mediterania"]=1,["medomalakufobia"]=1,["medortofobia"]=1,["megalofobia"]=1,["megalomania"]=1,["megamalofilia"]=1,["mekania"]=1,
    ["mekanofobia"]=1,["melanesia"]=1,["melania"]=1,["melankolia"]=1,["melanofobia"]=1,["melia"]=1,["meliosmifolia"]=1,["melofobia"]=1,["memetia"]=1,["memorabilia"]=1,
    ["mempermanusia"]=1,["mempermulia"]=1,["mencia"]=1,["mendunia"]=1,["mengarunia"]=1,["meningitofobia"]=1,["menofobia"]=1,["menoragia"]=1,["menyedia"]=1,["menyelia"]=1,
    ["menyia"]=1,["meralgia"]=1,["merazia"]=1,["merintofobia"]=1,["merremia"]=1,["mesopotamia"]=1,["metalofobia"]=1,["metatesiofobia"]=1,["meteorofobia"]=1,["metifobia"]=1,
    ["metonimia"]=1,["metrofilia"]=1,["metrofobia"]=1,["metroragia"]=1,["mezzetia"]=1,["mia"]=1,["mialgia"]=1,["micaria"]=1,["michelia"]=1,["mikofobia"]=1,
    ["mikrofobia"]=1,["mikrokimia"]=1,["mikronesia"]=1,["mikropsia"]=1,["mikrosefalia"]=1,["miksofobia"]=1,["miliaria"]=1,["milletia"]=1,["miokardia"]=1,["miopia"]=1,
    ["miotonia"]=1,["mirmekofilia"]=1,["mirmekofobia"]=1,["misofilia"]=1,["misofobia"]=1,["mitofobia"]=1,["mitokondria"]=1,["mitomania"]=1,["mnemofobia"]=1,["mofilia"]=1,
    ["moldavia"]=1,["monalia"]=1,["mongolia"]=1,["monnieria"]=1,["monofobia"]=1,["monomania"]=1,["morabilia"]=1,["mortuaria"]=1,["motefobia"]=1,["motorfobia"]=1,
    ["mulia"]=1,["multimedia"]=1,["mumia"]=1,["munia"]=1,["murofobia"]=1,["musikofobia"]=1,["musofobia"]=1,["namibia"]=1,["nanofilia"]=1,["nebulafobia"]=1,
    ["nefofobia"]=1,["negrofilia"]=1,["nekrofilia"]=1,["nekrofobia"]=1,["nekrolalia"]=1,["nelofobia"]=1,["nemofilia"]=1,["neofarmafobia"]=1,["neofilia"]=1,["neofobia"]=1,
    ["neoscartechinia"]=1,["neptunia"]=1,["nerifolia"]=1,["neriifolia"]=1,["neuralgia"]=1,["neurastenia"]=1,["neuroglia"]=1,["neurokimia"]=1,["nia"]=1,["nicolaia"]=1,
    ["nigeria"]=1,["niktofobia"]=1,["niktohilofobia"]=1,["nimfomania"]=1,["nitalia"]=1,["nofobia"]=1,["noglosia"]=1,["noktifilia"]=1,["noktifobia"]=1,["nokturia"]=1,
    ["nomania"]=1,["nomofobia"]=1,["nonkimia"]=1,["nopia"]=1,["noragia"]=1,["norrisia"]=1,["norwegia"]=1,["nosemafobia"]=1,["nosofobia"]=1,["nosokomefobia"]=1,
    ["nostalgia"]=1,["nostofobia"]=1,["novalhokadia"]=1,["noverkafobia"]=1,["nukleomitufobia"]=1,["numeralia"]=1,["numerofobia"]=1,["nusia"]=1,["nyctalopia"]=1,["obesofobia"]=1,
    ["oblongifolia"]=1,["obtusifolia"]=1,["oceania"]=1,["odontofobia"]=1,["ofidiofobia"]=1,["ofiofilia"]=1,["oftalmia"]=1,["okimia"]=1,["oklofobia"]=1,["okofobia"]=1,
    ["oktofobia"]=1,["oleokimia"]=1,["olfaktofobia"]=1,["olia"]=1,["oligofremia"]=1,["oligofrenia"]=1,["oligositemia"]=1,["oligozospermia"]=1,["oliguria"]=1,["ombrofobia"]=1,
    ["ometafobia"]=1,["onikofagia"]=1,["oniomania"]=1,["oogonia"]=1,["oppositifolia"]=1,["orania"]=1,["oratoria"]=1,["organisasiperdagangandunia"]=1,["oria"]=1,["ormosia"]=1,
    ["ornitofobia"]=1,["ornotofilia"]=1,["ortodonsia"]=1,["ortoreksia"]=1,["oseania"]=1,["osfresiofobia"]=1,["osilopsia"]=1,["osmofobia"]=1,["osteomalasia"]=1,["osteopenia"]=1,
    ["ostrakonofobia"]=1,["ovalifolia"]=1,["paederia"]=1,["paedofilia"]=1,["paedophilia"]=1,["pagofobia"]=1,["pakambia"]=1,["palilalia"]=1,["pametia"]=1,["panfobia"]=1,
    ["paniradia"]=1,["panitia"]=1,["panleukopenia"]=1,["panofobia"]=1,["panspermia"]=1,["pantofobia"]=1,["papirofobia"]=1,["parafasia"]=1,["parafemia"]=1,["parafilia"]=1,
    ["parafobia"]=1,["parafrenia"]=1,["paralgesia"]=1,["paralipofobia"]=1,["parameria"]=1,["paramignia"]=1,["paranoia"]=1,["paraplegia"]=1,["parasitofobia"]=1,["paraskavedekatriafobia"]=1,
    ["parasomnia"]=1,["parestesia"]=1,["paria"]=1,["parkia"]=1,["parlementaria"]=1,["paronisia"]=1,["paronomasia"]=1,["parousia"]=1,["partenofobia"]=1,["parturifobia"]=1,
    ["parvifelia"]=1,["parvifolia"]=1,["patenofilia"]=1,["patofobia"]=1,["patokimia"]=1,["patria"]=1,["patroiofobia"]=1,["pedikulofobia"]=1,["pediofobia"]=1,["pedofilia"]=1,
    ["pedofobia"]=1,["pekatofobia"]=1,["peladofobia"]=1,["pelagrofobia"]=1,["pemulia"]=1,["peniafobia"]=1,["penterafobia"]=1,["penyedia"]=1,["penyelia"]=1,["perazia"]=1,
    ["peria"]=1,["periodonsia"]=1,["peristerofilia"]=1,["persia"]=1,["personalia"]=1,["petia"]=1,["petrofilia"]=1,["petrokimia"]=1,["petunia"]=1,["phobia"]=1,
    ["pia"]=1,["piezokimia"]=1,["pigofilia"]=1,["pireksia"]=1,["pireksiofobia"]=1,["pirofobia"]=1,["piromania"]=1,["pisonia"]=1,["pistia"]=1,["piuria"]=1,
    ["plakofobia"]=1,["planaria"]=1,["planifolia"]=1,["plectocomia"]=1,["plenchonia"]=1,["plutofobia"]=1,["pluviofobia"]=1,["pneumatifobia"]=1,["pneumonia"]=1,["pnigerofobia"]=1,
    ["pnigofobia"]=1,["podofobia"]=1,["pogonofobia"]=1,["poinefobia"]=1,["pokreskofobia"]=1,["polandia"]=1,["polidipsia"]=1,["polifagia"]=1,["polinesia"]=1,["polinia"]=1,
    ["polisitemia"]=1,["politikofobia"]=1,["poliuria"]=1,["pollia"]=1,["pometia"]=1,["pongamia"]=1,["ponnetia"]=1,["porfiria"]=1,["porfirofobia"]=1,["potamofobia"]=1,
    ["potia"]=1,["potofobia"]=1,["pouzolzia"]=1,["pramuria"]=1,["prasetia"]=1,["preeklamsia"]=1,["presbiopia"]=1,["pria"]=1,["prinia"]=1,["proktofobia"]=1,
    ["prominensia"]=1,["prosofobia"]=1,["prosopagnosia"]=1,["prostodonsia"]=1,["proteinuria"]=1,["protuberansia"]=1,["pselismofobia"]=1,["pseudodemensia"]=1,["pseudoginekomastia"]=1,["psia"]=1,
    ["psikofobia"]=1,["psychotria"]=1,["pteridofobia"]=1,["pteromerhanofobia"]=1,["pteronofobia"]=1,["ptilia"]=1,["ptomania"]=1,["punia"]=1,["pupafobia"]=1,["pyrenaria"]=1,
    ["pyrifolia"]=1,["quadriplegia"]=1,["radiofobia"]=1,["radiokimia"]=1,["rafflesia"]=1,["rafia"]=1,["raflesia"]=1,["rahasia"]=1,["rahsia"]=1,["ralia"]=1,
    ["ramania"]=1,["ranidafobia"]=1,["raphia"]=1,["rapia"]=1,["rasia"]=1,["rauwolfia"]=1,["razia"]=1,["razzia"]=1,["rbia"]=1,["reagensia"]=1,
    ["regia"]=1,["rektofobia"]=1,["remenia"]=1,["reofilia"]=1,["reptilia"]=1,["republikserbiabosnia"]=1,["reqia"]=1,["restomania"]=1,["retrofilia"]=1,["rhodamnia"]=1,
    ["rhododendrifolia"]=1,["rhoifolia"]=1,["rhombifolia"]=1,["ria"]=1,["richmondia"]=1,["riketsia"]=1,["rofilia"]=1,["roftalmia"]=1,["romania"]=1,["rotundifolia"]=1,
    ["rsia"]=1,["ruffia"]=1,["rumania"]=1,["rumbia"]=1,["rumenia"]=1,["ruminansia"]=1,["rusia"]=1,["saintpaulia"]=1,["sakramentalia"]=1,["salindia"]=1,
    ["salvinia"]=1,["samuderahindia"]=1,["samuderaindonesia"]=1,["sangria"]=1,["sansevieria"]=1,["santiria"]=1,["saponaria"]=1,["sarkofilia"]=1,["sarkopenia"]=1,["satanofobia"]=1,
    ["satria"]=1,["sbiopia"]=1,["scleria"]=1,["scorparia"]=1,["sebahagia"]=1,["secendekia"]=1,["seceria"]=1,["sedia"]=1,["sedunia"]=1,["seia"]=1,
    ["seksofobia"]=1,["seksomnia"]=1,["selafobia"]=1,["selakofobia"]=1,["selandia"]=1,["selenofobia"]=1,["selia"]=1,["semikimia"]=1,["semulia"]=1,["senofobia"]=1,
    ["senoglosofobia"]=1,["sepadia"]=1,["sepia"]=1,["septisemia"]=1,["serbia"]=1,["serealia"]=1,["sesbania"]=1,["sesifolia"]=1,["sessilifolia"]=1,["setaria"]=1,
    ["seteria"]=1,["setia"]=1,["seusia"]=1,["sfeksofobia"]=1,["sia"]=1,["sianofobia"]=1,["siberfobia"]=1,["siberia"]=1,["sibofobia"]=1,["siderodromofobia"]=1,
    ["siderofobia"]=1,["sideropenia"]=1,["sifilobia"]=1,["sifilofobia"]=1,["siklofobia"]=1,["silia"]=1,["simbolofobia"]=1,["simetrofobia"]=1,["simia"]=1,["simofobia"]=1,
    ["simplicifolia"]=1,["simplisia"]=1,["sincia"]=1,["sinefilia"]=1,["sinekia"]=1,["sinestesia"]=1,["singenesofobia"]=1,["sinistrofobia"]=1,["sinofilia"]=1,["sinofobia"]=1,
    ["sinovia"]=1,["sipridofobia"]=1,["siria"]=1,["sitofobia"]=1,["sitokimia"]=1,["sitomania"]=1,["skabiofobia"]=1,["skandanavia"]=1,["skandinavia"]=1,["skelerofobia"]=1,
    ["skiofilia"]=1,["skiofobia"]=1,["skizofrenia"]=1,["skolionofobia"]=1,["skopofobia"]=1,["skoria"]=1,["skotlandia"]=1,["skotomafobia"]=1,["skotopia"]=1,["sloetia"]=1,
    ["slovenia"]=1,["slowakia"]=1,["smoplasia"]=1,["sodomia"]=1,["sohnetatia"]=1,["solaria"]=1,["somalia"]=1,["somnifobia"]=1,["sonneratia"]=1,["sororia"]=1,
    ["soserafobia"]=1,["sosialfobia"]=1,["sosiofobia"]=1,["soteriofobia"]=1,["spasefobia"]=1,["spasmofilia"]=1,["spektrofobia"]=1,["spektrokimia"]=1,["spermatofobia"]=1,["spermofobia"]=1,
    ["staurofobia"]=1,["stegofilia"]=1,["stenofobia"]=1,["sterculia"]=1,["stereokimia"]=1,["stesia"]=1,["stevia"]=1,["stia"]=1,["stigmatofilia"]=1,["stovia"]=1,
    ["streptopelia"]=1,["strombosia"]=1,["sukaria"]=1,["sumpia"]=1,["supositoria"]=1,["surifobia"]=1,["swedia"]=1,["swietenia"]=1,["syria"]=1,["tabernasia"]=1,
    ["tabia"]=1,["taeinofobia"]=1,["tafefobia"]=1,["tafia"]=1,["tafofobia"]=1,["takbahagia"]=1,["takceria"]=1,["takikardia"]=1,["takofobia"]=1,["taktersedia"]=1,
    ["talasemia"]=1,["talasofilia"]=1,["talasofobia"]=1,["tanatofobia"]=1,["tandia"]=1,["tania"]=1,["tanzania"]=1,["tapinofobia"]=1,["tarfia"]=1,["taria"]=1,
    ["tarrietia"]=1,["tasmania"]=1,["tasofobia"]=1,["taurofobia"]=1,["tectonia"]=1,["teknofilia"]=1,["teknofobia"]=1,["telefonofobia"]=1,["teleofobia"]=1,["telestesia"]=1,
    ["teofobia"]=1,["teologikofobia"]=1,["teomania"]=1,["teratofobia"]=1,["teratozoospermia"]=1,["terazia"]=1,["termaestesia"]=1,["terminalia"]=1,["termofilia"]=1,["termofobia"]=1,
    ["termokimia"]=1,["termulia"]=1,["tersedia"]=1,["tersia"]=1,["testofobia"]=1,["tetanofobia"]=1,["tetragonia"]=1,["textilia"]=1,["tia"]=1,["tiapia"]=1,
    ["tibia"]=1,["tiflofilia"]=1,["tifonia"]=1,["tiksofobia"]=1,["tilansia"]=1,["timbrofilia"]=1,["tinctoria"]=1,["titania"]=1,["tobakofilia"]=1,["toddalia"]=1,
    ["tokofobia"]=1,["tokopedia"]=1,["toksemia"]=1,["toksifobia"]=1,["tomofobia"]=1,["tonimia"]=1,["tonitrofobia"]=1,["tonsurfobia"]=1,["tonuria"]=1,["topofobia"]=1,
    ["toromia"]=1,["toxicaria"]=1,["toxicatia"]=1,["toxicoria"]=1,["transdiferensia"]=1,["transfobia"]=1,["transpria"]=1,["traumatofobia"]=1,["treycinetia"]=1,["tria"]=1,
    ["trifolia"]=1,["trikasia"]=1,["trikofobia"]=1,["trikopatofobia"]=1,["trikotilomania"]=1,["trinervia"]=1,["tripanofobia"]=1,["triphasia"]=1,["tripofobia"]=1,["triprasetia"]=1,
    ["trisandia"]=1,["triskaidekafobia"]=1,["trivernia"]=1,["trivia"]=1,["trokimia"]=1,["trombositemia"]=1,["trombositopenia"]=1,["tropia"]=1,["tropidia"]=1,["troragia"]=1,
    ["tuberkulofobia"]=1,["tunia"]=1,["tunisia"]=1,["turbelaria"]=1,["turiceelaria"]=1,["turofilia"]=1,["uforia"]=1,["uia"]=1,["ukonisia"]=1,["ukopenia"]=1,
    ["ulmifolia"]=1,["umonia"]=1,["uncaria"]=1,["unia"]=1,["universalia"]=1,["uraemia"]=1,["uralgia"]=1,["uranofobia"]=1,["uraria"]=1,["urasia"]=1,
    ["uremia"]=1,["uria"]=1,["urinaria"]=1,["urofobia"]=1,["uroglia"]=1,["urtikaria"]=1,["usia"]=1,["utanasia"]=1,["utopia"]=1,["utranomalopia"]=1,
    ["utranopia"]=1,["utriculania"]=1,["uvaria"]=1,["vaksinofobia"]=1,["valeria"]=1,["varia"]=1,["vehofobia"]=1,["veitehia"]=1,["venesia"]=1,["venustrafobia"]=1,
    ["verminofobia"]=1,["vernonia"]=1,["vestifobia"]=1,["vetivertia"]=1,["via"]=1,["vicia"]=1,["vigia"]=1,["virginia"]=1,["virginitifobia"]=1,["vitrikofobia"]=1,
    ["voadzeia"]=1,["vokalia"]=1,["vulvodinia"]=1,["waria"]=1,["wedelia"]=1,["wijayamulia"]=1,["wikafobia"]=1,["willughbeia"]=1,["woodfordia"]=1,["wrightia"]=1,
    ["xantokromia"]=1,["xantopsia"]=1,["xenia"]=1,["xenofilia"]=1,["xenofobia"]=1,["xenoglosia"]=1,["xenoglosofilia"]=1,["xenoglosofobia"]=1,["xenomania"]=1,["xenopobia"]=1,
    ["xerofilia"]=1,["xerofobia"]=1,["xeroftalmia"]=1,["xerostomia"]=1,["xilofobia"]=1,["xirofobia"]=1,["yogia"]=1,["yordania"]=1,["yugoslavia"]=1,["yusticia"]=1,
    ["yustisia"]=1,["zakaria"]=1,["zakharia"]=1,["zambia"]=1,["zelofilia"]=1,["zelofobia"]=1,["zemifobia"]=1,["zirkonia"]=1,["zodia"]=1,["zoodomatia"]=1,
    ["zoofilia"]=1,["zoofobia"]=1,["abesif"]=1,["abrasif"]=1,["abusif"]=1,["adhesif"]=1,["adrif"]=1,["agresif"]=1,["akuif"]=1,["alif"]=1,
    ["anaglif"]=1,["antihipertensif"]=1,["antikorosif"]=1,["antipasif"]=1,["antitusif"]=1,["arif"]=1,["bermuradif"]=1,["bertakrif"]=1,["bertarif"]=1,["brigif"]=1,
    ["daif"]=1,["defensif"]=1,["delusif"]=1,["depresif"]=1,["dif"]=1,["diskursif"]=1,["drif"]=1,["egresif"]=1,["eksesif"]=1,["eksklusif"]=1,
    ["ekskursif"]=1,["ekslusif"]=1,["ekspansif"]=1,["eksplosif"]=1,["ekspresif"]=1,["ekstensif"]=1,["ekstraserbasif"]=1,["ekstrusif"]=1,["elusif"]=1,["esif"]=1,
    ["foraminif"]=1,["forklif"]=1,["glif"]=1,["hanif"]=1,["hieroglif"]=1,["ilusif"]=1,["implosif"]=1,["impresif"]=1,["impulsif"]=1,["imunosupresif"]=1,
    ["inesif"]=1,["infleksif"]=1,["ingresif"]=1,["inklusif"]=1,["intensif"]=1,["invasif"]=1,["kalsif"]=1,["kif"]=1,["klif"]=1,["klusif"]=1,
    ["koersif"]=1,["kohesif"]=1,["kolusif"]=1,["komisif"]=1,["komprehensif"]=1,["kompulsif"]=1,["kondusif"]=1,["konif"]=1,["konklusif"]=1,["konsesif"]=1,
    ["konvulsif"]=1,["korosif"]=1,["kursif"]=1,["laif"]=1,["lamalif"]=1,["lif"]=1,["lusif"]=1,["manif"]=1,["masif"]=1,["maukif"]=1,
    ["mengagresif"]=1,["mengintensif"]=1,["mualif"]=1,["mukhalif"]=1,["muradif"]=1,["mutahalif"]=1,["mutasawif"]=1,["mutawif"]=1,["naif"]=1,["nif"]=1,
    ["nonantipasif"]=1,["nontarif"]=1,["obsesif"]=1,["ofensif"]=1,["oklusif"]=1,["ostensif"]=1,["pasif"]=1,["pelaif"]=1,["permansif"]=1,["permisif"]=1,
    ["persuasif"]=1,["petroglif"]=1,["plosif"]=1,["posesif"]=1,["progresif"]=1,["radif"]=1,["refleksif"]=1,["regresif"]=1,["represif"]=1,["resesif"]=1,
    ["residif"]=1,["responsif"]=1,["retrogresif"]=1,["rif"]=1,["roglif"]=1,["saif"]=1,["seagresif"]=1,["searif"]=1,["seeksklusif"]=1,["seekstensif"]=1,
    ["seintensif"]=1,["semasif"]=1,["sepasif"]=1,["sherif"]=1,["sif"]=1,["sponsif"]=1,["subversif"]=1,["sudorif"]=1,["suksesif"]=1,["superintensif"]=1,
    ["supresif"]=1,["syarif"]=1,["tafoglif"]=1,["takarif"]=1,["taklif"]=1,["takrif"]=1,["tarif"]=1,["tasrif"]=1,["teragresif"]=1,["terpasif"]=1,
    ["trif"]=1,["usif"]=1,["wakif"]=1,["wif"]=1,["yonif"]=1,["abadiat"]=1,["afiat"]=1,["ahadiat"]=1,["akiat"]=1,["alimiat"]=1,
    ["antikuariat"]=1,["baiat"]=1,["bergeliat"]=1,["bergiat"]=1,["berkhasiat"]=1,["berkiat"]=1,["bermaksiat"]=1,["berniat"]=1,["bersekretariat"]=1,["bertabiat"]=1,
    ["berwasiat"]=1,["biat"]=1,["dahiat"]=1,["diat"]=1,["dibaiat"]=1,["duriat"]=1,["ekspatriat"]=1,["fiat"]=1,["geliat"]=1,["gemiat"]=1,
    ["giat"]=1,["iat"]=1,["ilahiat"]=1,["impresariat"]=1,["intermediat"]=1,["jariat"]=1,["juriat"]=1,["kaifiat"]=1,["kasiat"]=1,["kepiat"]=1,
    ["keriat"]=1,["khasiat"]=1,["kiat"]=1,["komisariat"]=1,["kretariat"]=1,["liat"]=1,["lisensiat"]=1,["maksiat"]=1,["meliat"]=1,["membaiat"]=1,
    ["memfiat"]=1,["memiat"]=1,["mempergiat"]=1,["memplagiat"]=1,["menggeliat"]=1,["mengiat"]=1,["menyiat"]=1,["ngeliat"]=1,["niat"]=1,["notariat"]=1,
    ["novisiat"]=1,["paliat"]=1,["pegiat"]=1,["penggiat"]=1,["pewasiat"]=1,["piat"]=1,["plagiat"]=1,["prekariat"]=1,["proficiat"]=1,["proletariat"]=1,
    ["rubaiat"]=1,["ruhbaniat"]=1,["rukiat"]=1,["sangkiat"]=1,["sariat"]=1,["sekretariat"]=1,["seriat"]=1,["siat"]=1,["syamsiat"]=1,["syariat"]=1,
    ["tabiat"]=1,["tahiat"]=1,["takbiat"]=1,["tanbiat"]=1,["tergeliat"]=1,["terniat"]=1,["trifoliat"]=1,["uniat"]=1,["vikariat"]=1,["walafiat"]=1,
    ["walalfiat"]=1,["wasiat"]=1,["zariat"]=1,["zawiat"]=1,["zuriat"]=1,["ablatif"]=1,["abortif"]=1,["absorptif"]=1,["adaptif"]=1,["adiktif"]=1,
    ["aditif"]=1,["adjektif"]=1,["adjudikatif"]=1,["administratif"]=1,["adoptif"]=1,["adsorptif"]=1,["adventif"]=1,["afektif"]=1,["aferitif"]=1,["afirmatif"]=1,
    ["agentif"]=1,["agitatif"]=1,["aglutinatif"]=1,["agregatif"]=1,["ajektif"]=1,["akomodatif"]=1,["akseleratif"]=1,["aktif"]=1,["akumulatif"]=1,["akusatif"]=1,
    ["alatif"]=1,["alteratif"]=1,["alternatif"]=1,["amelioratif"]=1,["antidegeneratif"]=1,["antisipatif"]=1,["aperitif"]=1,["aplikatif"]=1,["apositif"]=1,["apresiatif"]=1,
    ["argumentatif"]=1,["artikulatif"]=1,["asertif"]=1,["asimilatif"]=1,["askriptif"]=1,["asosiatif"]=1,["aspiratif"]=1,["asumptif"]=1,["asumtif"]=1,["atif"]=1,
    ["atraktif"]=1,["atributif"]=1,["auditif"]=1,["augmentatif"]=1,["automotif"]=1,["benefaktif"]=1,["berinisiatif"]=1,["bermotif"]=1,["berobjektif"]=1,["bervariatif"]=1,
    ["bioaditif"]=1,["bioaktif"]=1,["datif"]=1,["dedikatif"]=1,["deduktif"]=1,["defektif"]=1,["definitif"]=1,["deformatif"]=1,["degeneratif"]=1,["degradatif"]=1,
    ["deklaratif"]=1,["dekoratif"]=1,["demonstratif"]=1,["denotatif"]=1,["derivatif"]=1,["desideratif"]=1,["deskriptif"]=1,["destruktif"]=1,["detektif"]=1,["determinatif"]=1,
    ["diapositif"]=1,["digestif"]=1,["dikatif"]=1,["diminutif"]=1,["direktif"]=1,["disinsentif"]=1,["disintegratif"]=1,["disjungtif"]=1,["diskriminatif"]=1,["disosiatif"]=1,
    ["disruptif"]=1,["distingtif"]=1,["distributif"]=1,["ditransitif"]=1,["dukatif"]=1,["duktif"]=1,["duplikatif"]=1,["duratif"]=1,["dwitransitif"]=1,["edukatif"]=1,
    ["efektif"]=1,["ejektif"]=1,["eksekutif"]=1,["eksplikatif"]=1,["eksploitatif"]=1,["eksploitif"]=1,["eksploratif"]=1,["ekstraktif"]=1,["ekstrapunitif"]=1,["ekuatif"]=1,
    ["elaboratif"]=1,["elatif"]=1,["elektif"]=1,["elektromotif"]=1,["elektronegatif"]=1,["elektropositif"]=1,["emansipatif"]=1,["emotif"]=1,["enumeratif"]=1,["ergatif"]=1,
    ["eskalatif"]=1,["evaluatif"]=1,["evokatif"]=1,["evolutif"]=1,["faktif"]=1,["faktitif"]=1,["fakultatif"]=1,["fermentatif"]=1,["figuratif"]=1,["fiktif"]=1,
    ["finitif"]=1,["fktif"]=1,["flektif"]=1,["fluktuatif"]=1,["formatif"]=1,["fotokonduktif"]=1,["frekuentatif"]=1,["frikatif"]=1,["gatif"]=1,["generatif"]=1,
    ["genetif"]=1,["genitif"]=1,["gislatif"]=1,["gulatif"]=1,["habilitatif"]=1,["habituatif"]=1,["hatif"]=1,["heterofermentatif"]=1,["heteronormatif"]=1,["hiperaktif"]=1,
    ["hipersensitif"]=1,["homofermentatif"]=1,["ilatif"]=1,["ilustratif"]=1,["imajinatif"]=1,["imitatif"]=1,["imperatif"]=1,["imperfektif"]=1,["imunoreaktif"]=1,["indikatif"]=1,
    ["indoktrinatif"]=1,["induktif"]=1,["infektif"]=1,["infinitif"]=1,["inflektif"]=1,["informatif"]=1,["inisiatif"]=1,["inkoatif"]=1,["inkompletif"]=1,["inkorporatif"]=1,
    ["inovatif"]=1,["insentif"]=1,["inseptif"]=1,["insinuatif"]=1,["inspektif"]=1,["inspiratif"]=1,["instingtif"]=1,["instruktif"]=1,["instrumentatif"]=1,["integratif"]=1,
    ["interaktif"]=1,["interogatif"]=1,["interpretatif"]=1,["interpretif"]=1,["intransitif"]=1,["intropunitif"]=1,["intuitif"]=1,["inventif"]=1,["investigatif"]=1,["iritatif"]=1,
    ["isolatif"]=1,["iteratif"]=1,["judikatif"]=1,["kalkulatif"]=1,["kapasitif"]=1,["karitatif"]=1,["karminatif"]=1,["kausatif"]=1,["klaratif"]=1,["kognatif"]=1,
    ["kognitif"]=1,["kolaboratif"]=1,["kolektif"]=1,["koligatif"]=1,["komitatif"]=1,["komparatif"]=1,["kompetitif"]=1,["kompletif"]=1,["komplikatif"]=1,["komulatif"]=1,
    ["komunikatif"]=1,["komutatif"]=1,["konatif"]=1,["konektif"]=1,["konfektif"]=1,["konfrontatif"]=1,["konjungtif"]=1,["konotatif"]=1,["konsekutif"]=1,["konservatif"]=1,
    ["konspiratif"]=1,["konstatatif"]=1,["konstitutif"]=1,["konstriktif"]=1,["konstruktif"]=1,["konsultatif"]=1,["konsumtif"]=1,["kontemplatif"]=1,["kontinuatif"]=1,["kontradiktif"]=1,
    ["kontraktif"]=1,["kontrapositif"]=1,["kontraproduktif"]=1,["kontraseptif"]=1,["kontributif"]=1,["konvektif"]=1,["kooperatif"]=1,["kooptatif"]=1,["koordinatif"]=1,["koperatif"]=1,
    ["kopulatif"]=1,["koratif"]=1,["korektif"]=1,["korelatif"]=1,["korporatif"]=1,["koruptif"]=1,["kreatif"]=1,["kualitatif"]=1,["kuantitatif"]=1,["kuasilegislatif"]=1,
    ["kuatif"]=1,["kulatif"]=1,["kumulatif"]=1,["kuratif"]=1,["kwantitatif"]=1,["laksatif"]=1,["latif"]=1,["legislatif"]=1,["legitimatif"]=1,["limitatif"]=1,
    ["lioratif"]=1,["lokatif"]=1,["lokomotif"]=1,["lukratif"]=1,["maladministratif"]=1,["manipulatif"]=1,["meditatif"]=1,["modifikatif"]=1,["monstratif"]=1,["motif"]=1,
    ["multiperspektif"]=1,["multiplikatif"]=1,["naratif"]=1,["nefaktif"]=1,["negatif"]=1,["neratif"]=1,["nitif"]=1,["nominatif"]=1,["nonaktif"]=1,["nondiskriminatif"]=1,
    ["nondistingtif"]=1,["nonkooperatif"]=1,["nonnominatif"]=1,["nonpredikatif"]=1,["nonproduktif"]=1,["nonretroaktif"]=1,["normatif"]=1,["notatif"]=1,["nutritif"]=1,["objektif"]=1,
    ["obligatif"]=1,["obstruktif"]=1,["obviatif"]=1,["obyektif"]=1,["oksidatif"]=1,["operatif"]=1,["optatif"]=1,["otomotif"]=1,["otoritatif"]=1,["overaktif"]=1,
    ["paliatif"]=1,["partisipatif"]=1,["partitif"]=1,["pengaktif"]=1,["perfektif"]=1,["performatif"]=1,["perseptif"]=1,["perspektif"]=1,["peyoratif"]=1,["polutif"]=1,
    ["positif"]=1,["predikatif"]=1,["prerogatif"]=1,["preskriptif"]=1,["preventif"]=1,["primitif"]=1,["privatif"]=1,["proaktif"]=1,["produktif"]=1,["prolatif"]=1,
    ["promotif"]=1,["prospektif"]=1,["protektif"]=1,["provokatif"]=1,["proyektif"]=1,["psikoaktif"]=1,["ptif"]=1,["punitif"]=1,["purgatif"]=1,["radiatif"]=1,
    ["radioaktif"]=1,["ratif"]=1,["reaktif"]=1,["reduktif"]=1,["reflektif"]=1,["reformatif"]=1,["regulatif"]=1,["rehabilitatif"]=1,["rekonsiliatif"]=1,["rekonstruktif"]=1,
    ["rekreatif"]=1,["relatif"]=1,["repetitif"]=1,["representatif"]=1,["reproduktif"]=1,["reseptif"]=1,["resistif"]=1,["resitatif"]=1,["restoratif"]=1,["restriktif"]=1,
    ["retroaktif"]=1,["retrospektif"]=1,["rivatif"]=1,["rogatif"]=1,["seaktif"]=1,["sedatif"]=1,["seefektif"]=1,["segregatif"]=1,["sekomunikatif"]=1,["selektif"]=1,
    ["sensitif"]=1,["seobjektif"]=1,["seobyektif"]=1,["sesatif"]=1,["siatif"]=1,["signifikatif"]=1,["simplikatif"]=1,["simulfaktif"]=1,["skriptif"]=1,["solutif"]=1,
    ["spekulatif"]=1,["sportif"]=1,["statif"]=1,["stif"]=1,["stigatif"]=1,["stimulatif"]=1,["struktif"]=1,["subjektif"]=1,["subordinatif"]=1,["substantif"]=1,
    ["substitutif"]=1,["subyektif"]=1,["sugestif"]=1,["sumatif"]=1,["superkonduktif"]=1,["superlatif"]=1,["supersensitif"]=1,["suportif"]=1,["takaditif"]=1,["takaktif"]=1,
    ["takefektif"]=1,["takobjektif"]=1,["taktransitif"]=1,["tatif"]=1,["tentatif"]=1,["teraktif"]=1,["tif"]=1,["transaktif"]=1,["transformatif"]=1,["transitif"]=1,
    ["translatif"]=1,["troaktif"]=1,["ultrakonservatif"]=1,["valuatif"]=1,["variatif"]=1,["vegetatif"]=1,["vokatif"]=1,["yudikatif"]=1,["adaks"]=1,["afiks"]=1,
    ["afluks"]=1,["agrokompleks"]=1,["aks"]=1,["aloleks"]=1,["ambaks"]=1,["ambifiks"]=1,["anoks"]=1,["antefiks"]=1,["anteliks"]=1,["antiklimaks"]=1,
    ["antraks"]=1,["apendiks"]=1,["berafiks"]=1,["berklimaks"]=1,["berkonfiks"]=1,["berkonteks"]=1,["berkuteks"]=1,["berparadoks"]=1,["berprefiks"]=1,["bersufiks"]=1,
    ["bikonveks"]=1,["biloks"]=1,["birofaks"]=1,["biseks"]=1,["bkkks"]=1,["boks"]=1,["bomseks"]=1,["boraks"]=1,["botoks"]=1,["brafaks"]=1,
    ["cuaks"]=1,["deks"]=1,["detoks"]=1,["difaks"]=1,["diindeks"]=1,["diks"]=1,["disklimaks"]=1,["doks"]=1,["dominatriks"]=1,["dupleks"]=1,
    ["eks"]=1,["ekuinoks"]=1,["faks"]=1,["falotoraks"]=1,["fiks"]=1,["fiolaks"]=1,["flaks"]=1,["fleks"]=1,["fluks"]=1,["foniks"]=1,
    ["goks"]=1,["heks"]=1,["heliks"]=1,["heterodoks"]=1,["hidroponiks"]=1,["hijinks"]=1,["hiperteks"]=1,["hoaks"]=1,["homoseks"]=1,["indeks"]=1,
    ["infiks"]=1,["interfiks"]=1,["ireks"]=1,["isoleks"]=1,["karapaks"]=1,["kemorefleks"]=1,["klimaks"]=1,["koaks"]=1,["kodeks"]=1,["kompleks"]=1,
    ["konfiks"]=1,["konteks"]=1,["konveks"]=1,["korteks"]=1,["koteks"]=1,["kuadrupleks"]=1,["kuinoks"]=1,["kuteks"]=1,["laks"]=1,["larnaks"]=1,
    ["lateks"]=1,["leks"]=1,["liks"]=1,["loks"]=1,["lppks"]=1,["luks"]=1,["lureks"]=1,["maks"]=1,["matriks"]=1,["meaks"]=1,
    ["mengindeks"]=1,["mengklimaks"]=1,["mesotoraks"]=1,["mks"]=1,["multikompleks"]=1,["multipleks"]=1,["naks"]=1,["noks"]=1,["obeks"]=1,["oniks"]=1,
    ["ortodoks"]=1,["paks"]=1,["paradoks"]=1,["paralaks"]=1,["pengindeks"]=1,["pertamaks"]=1,["petromaks"]=1,["piks"]=1,["piroks"]=1,["plaks"]=1,
    ["pleks"]=1,["pmks"]=1,["poliklimaks"]=1,["prefiks"]=1,["protoraks"]=1,["radiks"]=1,["raks"]=1,["redoks"]=1,["refleks"]=1,["refluks"]=1,
    ["relaks"]=1,["retrofleks"]=1,["riks"]=1,["rileks"]=1,["rouks"]=1,["sefalotoraks"]=1,["seks"]=1,["serviks"]=1,["sfinks"]=1,["simpleks"]=1,
    ["simulfiks"]=1,["sinemapleks"]=1,["sinepleks"]=1,["sintaks"]=1,["sirkumfiks"]=1,["sirkumfleks"]=1,["sks"]=1,["sotoraks"]=1,["spandeks"]=1,["subteks"]=1,
    ["sufiks"]=1,["suks"]=1,["superheliks"]=1,["suprafiks"]=1,["taks"]=1,["teks"]=1,["teleks"]=1,["teleteks"]=1,["terodoks"]=1,["toks"]=1,
    ["toraks"]=1,["traks"]=1,["tripleks"]=1,["tromaks"]=1,["tubifeks"]=1,["tuks"]=1,["uks"]=1,["ultramikroskopiks"]=1,["ultraortodoks"]=1,["uniseks"]=1,
    ["veks"]=1,["verniks"]=1,["verteks"]=1,["videoteks"]=1,["vorteks"]=1,["yolks"]=1,["bordeaux"]=1,["lex"]=1,["sphinx"]=1,["unisex"]=1,
    ["bodrex"]=1,["komix"]=1,["gallierex"]=1,["addax"]=1,["aframax"]=1,["apterix"]=1,["bombyx"]=1,["caloperdrix"]=1,["caranx"]=1,["caronx"]=1,
    ["chalcococyx"]=1,["chx"]=1,["cimex"]=1,["circumfix"]=1,["coix"]=1,["confix"]=1,["cyathocalyx"]=1,["donax"]=1,["echinosorex"]=1,["forex"]=1,
    ["helix"]=1,["hystrix"]=1,["ilex"]=1,["index"]=1,["lux"]=1,["marx"]=1,["max"]=1,["melanoperdix"]=1,["meritrix"]=1,["microhierax"]=1,
    ["molitrix"]=1,["murex"]=1,["mystax"]=1,["naiasptatrix"]=1,["natrix"]=1,["nephotettix"]=1,["nephottotix"]=1,["ninox"]=1,["nontax"]=1,["nothopanax"]=1,
    ["nycticorax"]=1,["offax"]=1,["olfax"]=1,["ex"]=1,["prix"]=1,["annex"]=1,["croix"]=1,["deux"]=1,["complex"]=1,["ix"]=1,
    ["hapax"]=1,["rex"]=1,["klux"]=1,["mantoux"]=1,["box"]=1,["vox"]=1,["buraq"]=1,["ishraq"]=1,["falaq"]=1,["ishaq"]=1,
    ["istisqaq"]=1,["baiq"]=1,["thariq"]=1,["hafizul"]=1,["haq"]=1,["siddiq"]=1,["mutlaq"]=1,["munafiq"]=1,["razaq"]=1,["syafiq"]=1,
    ["taufiq"]=1,["istihqaq"]=1,["mantiq"]=1,["fariq"]=1,["barzaq"]=1,["nashriq"]=1,["attariq"]=1,["ifah"]=1,["ifrit"]=1,["iftar"]=1,
    ["iftitah"]=1,["ifere"]=1,["ifc"]=1,["iframe"]=1,["iflasi"]=1,["ifadah"]=1,["ifat"]=1,["iflas"]=1,["ifshon"]=1,
}


-- Mode filter SK Manual: "semua"/"mudah"/"normal"/"hard"
local S_ManualMode = "mudah"

task.spawn(function()
    local ok, data = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/WhoIsGenn/VictoriaHub/refs/heads/main/Loader/kbbi.txt")
    end)
    if ok and data and #data > 1000 then
        for line in data:gmatch("[^\n\r]+") do
            addWord(line:gsub("%s+",""):lower():gsub("[^a-z]",""))
        end
        for _,ws in pairs(ByLetter) do totalWords=totalWords+#ws end
        kbbiLoaded=true; kbbiStatus="✅ "..totalWords.." Words"
        if ParaDB then pcall(function()
            ParaDB:SetDesc("Source: GitHub (VictoriaHub)\nTotal: "..totalWords.." Words\nStatus: "..kbbiStatus)
        end) end
        if ParaRarity then pcall(function() ParaRarity:SetDesc(getRarityText()) end) end
        WindUI:Notify({Title="KBBI Ready!",Content=totalWords.." Words siap",Icon="book-open",Duration=4})
    else
        for _,w in ipairs({"ada","adik","air","ajak","ajar","akan","akar","akhir","aku","alam","alat","aman","anak","aneh","angin","api","apel","arah","arus","asah","asal","atap","atas","ayah","baik","baju","baru","batas","batu","bawa","besar","bisa","bola","buah","bunga","buruk","cabai","cahaya","cair","cakap","calon","cantik","capek","cari","cedera","cepat","cerita","cermat","cinta","cocok","cukup","curang","curi","dagang","dalam","damai","dapur","darah","darat","dasar","datang","daun","dekat","dengan","depan","deras","desa","diam","dingin","diri","dosa","duduk","duka","dulu","dunia","duri","dusta","edar","ejek","ekor","emas","enam","enak","erat","esok","fajar","fakta","fisik","gadis","gagah","gagal","galak","gambar","ganas","garang","gelap","gemuk","gembira","gerak","gigi","gigih","gila","girang","goreng","guna","gunung","guru","habis","hadap","hadir","halal","halus","hancur","hangat","hanya","hapus","harap","hari","harum","hasil","hati","hebat","hemat","hidup","hilang","hitam","hormat","hujan","hukum","hutan","ibu","ikut","ilmu","indah","ingin","ingat","istri","jaga","jalan","janda","jantan","jasa","jatuh","jauh","jawab","jelas","jenis","jiwa","jual","juara","jujur","juga","jumlah","kabar","kabur","kacau","kaki","kalah","kami","kanan","karya","kasih","kata","kaya","keras","kiri","kita","kuat","kurang","kurus","kursi","kunci","kulit","lagi","lain","lama","langit","lapor","lapar","lepas","lewat","liar","licin","lihat","lurus","lupa","lucu","laut","macam","mahir","main","maju","makna","malas","malam","makan","malu","manis","marah","masuk","mati","mawar","meja","minta","muda","murah","mulus","murni","musuh","naik","nama","nanti","nasib","nilai","nyata","nyaman","obat","olah","otak","orang","pagi","paham","pakai","panas","pandai","pantai","pasti","perlu","pikir","pilih","pintar","pohon","pulang","putih","rasa","rata","rekan","rendah","resmi","ringan","rindu","roboh","rumah","rusak","sabar","sakit","sama","santai","satu","senang","sehat","semua","siap","sikap","sopan","sulit","sunyi","susah","tabah","tahan","tajam","tali","tampil","tanda","tangguh","tanya","tarik","teguh","tekad","tenang","tengah","tepat","teras","terima","terus","tinggi","tidak","tujuan","turun","tugas","tulus","tutup","ubah","ujian","usaha","utama","wajah","waktu","warga","warna","wisata","yakin","zaman"}) do addWord(w) end
        for _,ws in pairs(ByLetter) do totalWords=totalWords+#ws end
        kbbiLoaded=true; kbbiStatus="⚠️ "..totalWords.." Words (fallback)"
        if ParaRarity then pcall(function() ParaRarity:SetDesc(getRarityText()) end) end
    end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- STATE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local S = {
    AutoAnswer  = false,
    ShowMonitor = false,
    ShowManual  = false,
    Delay       = 1.5,
    Speed       = 0.30,
    UsedWords   = {},
    CurrentWord = "-",
    LastSubmit  = "",
    Prefix      = "-",
    Suggestion  = "-",
    Terpakai    = 0,
    Benar       = 0,
    Salah       = 0,
    Busy        = false,
    Debug       = false,
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- MATCHUI HELPERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function getMatchUI()
    local g = LocalPlayer:FindFirstChild("PlayerGui")
    return g and g:FindFirstChild("MatchUI")
end
local function getBottomUI() local m=getMatchUI(); return m and m:FindFirstChild("BottomUI") end
local function getKeyboard() local b=getBottomUI(); return b and b:FindFirstChild("Keyboard") end
local function getTopUI() local b=getBottomUI(); return b and b:FindFirstChild("TopUI") end
local function getWordSubmit() local t=getTopUI(); return t and t:FindFirstChild("WordSubmit") end
local function getWordServerFrame() local t=getTopUI(); return t and t:FindFirstChild("WordServerFrame") end
local function getWordServerText()
    local wsf=getWordServerFrame(); if not wsf then return "" end
    local ws=wsf:FindFirstChild("WordServer"); if not ws then return "" end
    return (ws.Text or ""):gsub("%s+",""):lower():gsub("[^a-z]","")
end
local function isMyTurn()
    local kb=getKeyboard(); return kb~=nil and kb.Visible==true
end

local function getWordSlots()
    local ws=getWordSubmit(); if not ws then return {} end
    local slots={}
    for _,child in ipairs(ws:GetChildren()) do
        if child:IsA("TextLabel") then
            local ok,pos=pcall(function() return child.AbsolutePosition end)
            table.insert(slots,{obj=child,x=ok and pos.X or 0})
        end
    end
    table.sort(slots,function(a,b) return a.x<b.x end)
    return slots
end
local function getWordSubmitText()
    local chars={}
    for _,s in ipairs(getWordSlots()) do
        local t=s.obj.Text or ""
        if #t==1 and t:match("^%a$") then table.insert(chars,t:lower()) end
    end
    return table.concat(chars)
end
local function clearWordSubmit()
    for _,s in ipairs(getWordSlots()) do pcall(function() s.obj.Text="" end) end
    if S.Debug then print("[SK] cleared") end
    task.wait(0.05)
end

local function getKeys()
    local kb=getKeyboard(); if not kb then return {},nil end
    local keys,enter={},nil
    for _,row in ipairs(kb:GetChildren()) do
        if row:IsA("Frame") then
            for _,btn in ipairs(row:GetChildren()) do
                if btn:IsA("TextButton") then
                    local t=btn.Text:gsub("%s+","")
                    if #t==1 and t:match("^[A-Za-z]$") then keys[t:lower()]=btn end
                    if t:lower()=="enter" then enter=btn end
                end
            end
        end
    end
    return keys,enter
end
local function fireBtn(btn)
    if not btn or not btn.Parent then return false end
    pcall(function() for _,c in ipairs(getconnections(btn.Activated)) do c:Fire() end end)
    return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- WORD LOGIC
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function findBest(prefix, skipWord)
    prefix=prefix:lower():gsub("[^a-z]","")
    if #prefix==0 then return nil end
    local pool=ByLetter[prefix:sub(1,1)]; if not pool then return nil end
    local avail={}
    if #prefix==1 then
        for _,w in ipairs(pool) do
            if not S.UsedWords[w] and w~=skipWord then table.insert(avail,w) end
        end
    else
        for _,w in ipairs(pool) do
            if not S.UsedWords[w] and w~=skipWord and w:sub(1,#prefix)==prefix then table.insert(avail,w) end
        end
        if #avail==0 then
            for _,w in ipairs(pool) do
                if not S.UsedWords[w] and w~=skipWord then table.insert(avail,w) end
            end
        end
    end
    if #avail==0 then return nil end
    table.sort(avail,function(a,b)
        local ca=ByLetter[a:sub(-1)] and #ByLetter[a:sub(-1)] or 0
        local cb=ByLetter[b:sub(-1)] and #ByLetter[b:sub(-1)] or 0
        if ca~=cb then return ca<cb end
        return #a>#b
    end)
    return avail[1]
end

-- Difficulty: HardWords list + huruf akhir susah
-- HARD  = ada di HardWords ATAU huruf akhir f/x/q/z/v
-- NORMAL= huruf akhir b/d/g/p/c/j/y/h/w
-- MUDAH = sisanya (a/i/u/e/o/n/r/l/t/s/k/m)
local _eH={f=1,x=1,q=1,z=1,v=1}
local _eN={b=1,d=1,g=1,p=1,c=1,j=1,y=1,h=1,w=1}
local function getDiff(word)
    local l=word:sub(-1):lower()
    if HardWords[word] or _eH[l] then
        return "HARD",  Color3.fromRGB(160,20,20),  Color3.fromRGB(255,90,90)
    end
    if _eN[l] then
        return "NORMAL",Color3.fromRGB(140,90,0),   Color3.fromRGB(255,190,50)
    end
    return "MUDAH", Color3.fromRGB(20,100,40),  Color3.fromRGB(60,215,100)
end

-- Ambil sorted word list untuk SK Manual panel
local function getWordList(prefix, maxN)
    prefix=prefix:lower():gsub("[^a-z]","")
    maxN=maxN or 50
    if #prefix==0 then return {} end
    local pool=ByLetter[prefix:sub(1,1)]; if not pool then return {} end
    local avail={}
    if #prefix==1 then
        for _,w in ipairs(pool) do
            if not S.UsedWords[w] then table.insert(avail,w) end
        end
    else
        for _,w in ipairs(pool) do
            if not S.UsedWords[w] and w:sub(1,#prefix)==prefix then table.insert(avail,w) end
        end
        if #avail==0 then
            for _,w in ipairs(pool) do
                if not S.UsedWords[w] then table.insert(avail,w) end
            end
        end
    end
    -- Filter by mode: mudah = non-HARD, hard = HARD only
    local hard,normal,mudah={},{},{}
    for _,w in ipairs(avail) do
        local d=getDiff(w)
        if d=="HARD" then
            if S_ManualMode~="mudah" then table.insert(hard,w) end
        else
            if S_ManualMode~="hard" then
                if d=="NORMAL" then table.insert(normal,w)
                else table.insert(mudah,w) end
            end
        end
    end
    local function slen(t) table.sort(t,function(a,b) return #a>#b end) end
    slen(hard) slen(normal) slen(mudah)
    local res={}
    local hi,ni,mi=1,1,1
    while #res<maxN do
        local added=false
        if hi<=#hard   then table.insert(res,hard[hi]);   hi=hi+1   added=true end
        if #res>=maxN then break end
        if ni<=#normal then table.insert(res,normal[ni]); ni=ni+1   added=true end
        if #res>=maxN then break end
        if ni<=#normal then table.insert(res,normal[ni]); ni=ni+1   added=true end
        if #res>=maxN then break end
        if mi<=#mudah  then table.insert(res,mudah[mi]);  mi=mi+1   added=true end
        if #res>=maxN then break end
        if mi<=#mudah  then table.insert(res,mudah[mi]);  mi=mi+1   added=true end
        if #res>=maxN then break end
        if mi<=#mudah  then table.insert(res,mudah[mi]);  mi=mi+1   added=true end
        if not added then break end
    end
    return res
end



-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TYPE AND SUBMIT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function typeAndSubmit(word, prefix)
    local keys,enter=getKeys()
    task.wait(0.15)
    local existing=getWordSubmitText()
    if S.Debug then print("[SK] Typing '"..word.."' existing='"..existing.."'") end
    local si=1
    if #existing>0 then
        if word:sub(1,#existing)==existing then
            si=#existing+1
        else
            clearWordSubmit(); task.wait(0.3)
            local ri=getWordSubmitText()
            si=(#ri>0 and word:sub(1,#ri)==ri) and #ri+1 or 1
        end
    end
    for i=si,#word do
        if not isMyTurn() then return false end
        local ch=word:sub(i,i):lower()
        local btn=keys[ch]
        if btn then fireBtn(btn) end
        if S.Debug then print("[SK] '"..ch.."' ("..i.."/"..#word..")") end
        if R_TypeSound then pcall(function() R_TypeSound:FireServer() end) end
        task.wait(S.Speed+math.random()*0.05)
    end
    if S.Debug then task.wait(0.05) print("[SK] final='"..getWordSubmitText().."'") end
    task.wait(0.1)
    if enter then fireBtn(enter) end
    task.wait(0.05)
    pcall(function() R_SubmitWord:FireServer(word) end)
    return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- DO ANSWER
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function doAnswer(skipWord)
    if S.Busy or not S.AutoAnswer or not isMyTurn() then return end
    S.Busy=true
    task.spawn(function()
        task.wait(S.Delay)
        if not isMyTurn() or not S.AutoAnswer then S.Busy=false return end
        local wt=0
        while not kbbiLoaded and wt<5 do task.wait(0.3) wt=wt+0.3 end
        local prefix=S.Prefix
        if prefix=="" or prefix=="-" then
            prefix=getWordServerText()
            if prefix~="" then S.Prefix=prefix end
        end
        if prefix=="" or prefix=="-" then S.Busy=false return end
        local word=findBest(prefix,skipWord)
        if not word then
            WindUI:Notify({Title="Prefix '"..prefix:upper().."' Habis!",Content="Tidak ada kata.",Icon="alert-circle",Duration=3})
            S.Busy=false return
        end
        if S.Debug then print("[SK] Jawab: '"..word.."'") end
        local serverBefore=getWordServerText()
        local ok=typeAndSubmit(word,prefix)
        if not ok then S.Busy=false return end
        local el=0; local acc=false
        while el<2.0 do
            task.wait(0.1); el=el+0.1
            if not isMyTurn() then acc=true break end
            local cur=getWordServerText()
            if cur~="" and cur~=serverBefore then acc=true break end
        end
        if acc then
            S.UsedWords[word]=true; S.CurrentWord=word
            S.LastSubmit=word; S.Terpakai=S.Terpakai+1; S.Benar=S.Benar+1
            S.Suggestion=findBest(word:sub(-1),nil) or "-"
            WindUI:Notify({Title="✓ "..word:upper(),Content="→ Next: "..word:sub(-1):upper(),Icon="check",Duration=2})
        else
            S.UsedWords[word]=true; S.Salah=S.Salah+1
            WindUI:Notify({Title="✗ Ditolak: "..word:upper(),Content="Auto ganti kata...",Icon="alert-circle",Duration=2})
            clearWordSubmit(); task.wait(0.5)
            if isMyTurn() and S.AutoAnswer then S.Busy=false; doAnswer(word); return end
        end
        task.wait(0.3); S.Busy=false
    end)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- MONITOR GUI  (compact clean minimal)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local MON={}
local function buildMonitor()
    local old=LocalPlayer.PlayerGui:FindFirstChild("VHMonitor")
    if old then old:Destroy() end
    local sg=Instance.new("ScreenGui")
    sg.Name="VHMonitor" sg.ResetOnSpawn=false sg.DisplayOrder=20
    sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    sg.Parent=LocalPlayer:WaitForChild("PlayerGui")

    local card=Instance.new("Frame",sg)
    card.Size=UDim2.new(0,200,0,222) card.Position=UDim2.new(1,-210,1,-232)
    card.BackgroundColor3=Color3.fromRGB(11,13,22) card.BackgroundTransparency=0
    card.BorderSizePixel=0 card.Active=true card.Draggable=true
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,12)
    local cst=Instance.new("UIStroke",card)
    cst.Color=Color3.fromRGB(0,180,230) cst.Thickness=1 cst.Transparency=0.55

    local sbar=Instance.new("Frame",card)
    sbar.Size=UDim2.new(1,0,0,4) sbar.BackgroundColor3=Color3.fromRGB(0,160,220) sbar.BorderSizePixel=0
    Instance.new("UICorner",sbar).CornerRadius=UDim.new(0,12)
    local sbfix=Instance.new("Frame",sbar)
    sbfix.Size=UDim2.new(1,0,0.5,0) sbfix.Position=UDim2.new(0,0,0.5,0)
    sbfix.BackgroundColor3=Color3.fromRGB(0,160,220) sbfix.BorderSizePixel=0
    MON.statusBar=sbar MON.sbFix=sbfix

    local hdr=Instance.new("Frame",card)
    hdr.Size=UDim2.new(1,0,0,36) hdr.Position=UDim2.new(0,0,0,4) hdr.BackgroundTransparency=1
    local dot=Instance.new("Frame",hdr)
    dot.Size=UDim2.new(0,7,0,7) dot.Position=UDim2.new(0,13,0.5,-3)
    dot.BackgroundColor3=Color3.fromRGB(0,200,130) dot.BorderSizePixel=0
    Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0) MON.dot=dot
    local tl=Instance.new("TextLabel",hdr)
    tl.Size=UDim2.new(1,-60,0,16) tl.Position=UDim2.new(0,26,0,5) tl.BackgroundTransparency=1
    tl.Text="Victoria Hub" tl.TextColor3=Color3.fromRGB(235,240,255) tl.TextSize=12
    tl.Font=Enum.Font.GothamBold tl.TextXAlignment=Enum.TextXAlignment.Left
    local sl=Instance.new("TextLabel",hdr)
    sl.Size=UDim2.new(1,-60,0,12) sl.Position=UDim2.new(0,26,0,20) sl.BackgroundTransparency=1
    sl.Text="Sambung Kata" sl.TextColor3=Color3.fromRGB(80,140,200) sl.TextSize=9
    sl.Font=Enum.Font.Gotham sl.TextXAlignment=Enum.TextXAlignment.Left
    local cb=Instance.new("TextButton",hdr)
    cb.Size=UDim2.new(0,20,0,20) cb.Position=UDim2.new(1,-26,0.5,-10)
    cb.BackgroundColor3=Color3.fromRGB(28,30,46) cb.Text="✕"
    cb.TextColor3=Color3.fromRGB(100,120,160) cb.TextSize=10
    cb.Font=Enum.Font.GothamBold cb.BorderSizePixel=0
    Instance.new("UICorner",cb).CornerRadius=UDim.new(0,5)
    cb.MouseButton1Click:Connect(function() sg.Enabled=false S.ShowMonitor=false end)
    cb.MouseEnter:Connect(function() cb.BackgroundColor3=Color3.fromRGB(180,40,40) cb.TextColor3=Color3.fromRGB(255,255,255) end)
    cb.MouseLeave:Connect(function() cb.BackgroundColor3=Color3.fromRGB(28,30,46) cb.TextColor3=Color3.fromRGB(100,120,160) end)
    local div=Instance.new("Frame",card)
    div.Size=UDim2.new(1,-24,0,1) div.Position=UDim2.new(0,12,0,40)
    div.BackgroundColor3=Color3.fromRGB(30,50,80) div.BorderSizePixel=0

    local rf=Instance.new("Frame",card)
    rf.Size=UDim2.new(1,-16,0,168) rf.Position=UDim2.new(0,8,0,48) rf.BackgroundTransparency=1
    local ll=Instance.new("UIListLayout",rf)
    ll.SortOrder=Enum.SortOrder.LayoutOrder ll.Padding=UDim.new(0,3)

    local C={cyan=Color3.fromRGB(0,185,230),blue=Color3.fromRGB(60,120,255),green=Color3.fromRGB(40,210,120),yellow=Color3.fromRGB(255,195,50),purple=Color3.fromRGB(160,100,255)}
    local function makeRow(label,def,accent,order)
        local r=Instance.new("Frame",rf)
        r.Size=UDim2.new(1,0,0,26) r.BackgroundColor3=Color3.fromRGB(16,18,30)
        r.BackgroundTransparency=0.2 r.BorderSizePixel=0 r.LayoutOrder=order
        Instance.new("UICorner",r).CornerRadius=UDim.new(0,6)
        local b=Instance.new("Frame",r) b.Size=UDim2.new(0,2,0.6,0) b.Position=UDim2.new(0,0,0.2,0)
        b.BackgroundColor3=accent b.BorderSizePixel=0 Instance.new("UICorner",b).CornerRadius=UDim.new(1,0)
        local kl=Instance.new("TextLabel",r) kl.Size=UDim2.new(0,62,1,0) kl.Position=UDim2.new(0,8,0,0)
        kl.BackgroundTransparency=1 kl.Text=label kl.TextColor3=Color3.fromRGB(90,110,150) kl.TextSize=10
        kl.Font=Enum.Font.Gotham kl.TextXAlignment=Enum.TextXAlignment.Left
        local vl=Instance.new("TextLabel",r) vl.Size=UDim2.new(1,-74,1,0) vl.Position=UDim2.new(0,72,0,0)
        vl.BackgroundTransparency=1 vl.Text=def vl.TextColor3=Color3.fromRGB(210,225,255) vl.TextSize=11
        vl.Font=Enum.Font.GothamBold vl.TextXAlignment=Enum.TextXAlignment.Left vl.TextTruncate=Enum.TextTruncate.AtEnd
        return vl
    end
    MON.valStatus=makeRow("Status","—",C.cyan,1)
    MON.valPrefix=makeRow("Prefix","—",C.yellow,2)
    MON.valSugg  =makeRow("Saran", "—",C.green,3)
    MON.valWord  =makeRow("Kata",  "—",C.blue,4)

    local sr=Instance.new("Frame",rf)
    sr.Size=UDim2.new(1,0,0,26) sr.BackgroundColor3=Color3.fromRGB(16,18,30)
    sr.BackgroundTransparency=0.2 sr.BorderSizePixel=0 sr.LayoutOrder=5
    Instance.new("UICorner",sr).CornerRadius=UDim.new(0,6)
    local sb2=Instance.new("Frame",sr) sb2.Size=UDim2.new(0,2,0.6,0) sb2.Position=UDim2.new(0,0,0.2,0)
    sb2.BackgroundColor3=C.purple sb2.BorderSizePixel=0 Instance.new("UICorner",sb2).CornerRadius=UDim.new(1,0)
    local sk=Instance.new("TextLabel",sr) sk.Size=UDim2.new(0,40,1,0) sk.Position=UDim2.new(0,8,0,0)
    sk.BackgroundTransparency=1 sk.Text="Stats" sk.TextColor3=Color3.fromRGB(90,110,150) sk.TextSize=10
    sk.Font=Enum.Font.Gotham sk.TextXAlignment=Enum.TextXAlignment.Left
    local function makePill(x,bg,fg)
        local p=Instance.new("Frame",sr) p.Size=UDim2.new(0,38,0,18) p.Position=UDim2.new(0,x,0.5,-9)
        p.BackgroundColor3=bg p.BorderSizePixel=0 Instance.new("UICorner",p).CornerRadius=UDim.new(1,0)
        local l=Instance.new("TextLabel",p) l.Size=UDim2.new(1,0,1,0) l.BackgroundTransparency=1
        l.TextColor3=fg l.TextSize=10 l.Font=Enum.Font.GothamBold l.Text="0" return l
    end
    MON.pillTotal=makePill(48, Color3.fromRGB(25,40,70),  Color3.fromRGB(140,180,255))
    MON.pillBenar=makePill(92, Color3.fromRGB(15,45,30),  Color3.fromRGB(60,210,110))
    MON.pillSalah=makePill(136,Color3.fromRGB(45,15,15),  Color3.fromRGB(255,80,80))
    MON.valDB=makeRow("KBBI","loading...",C.cyan,6)

    local ft=Instance.new("TextLabel",card) ft.Size=UDim2.new(1,-16,0,14) ft.Position=UDim2.new(0,8,1,-16)
    ft.BackgroundTransparency=1 ft.Text="v40.0  •  Auto SK"
    ft.TextColor3=Color3.fromRGB(35,50,80) ft.TextSize=9
    ft.Font=Enum.Font.Gotham ft.TextXAlignment=Enum.TextXAlignment.Right
    MON.sg=sg MON.card=card
end

local function updateMonitor()
    if not MON.sg or not S.ShowMonitor then return end
    local myTurn=isMyTurn()
    local barC,dotC,stTxt
    if not S.AutoAnswer then barC=Color3.fromRGB(55,65,90) dotC=Color3.fromRGB(80,90,110) stTxt="OFF"
    elseif myTurn then barC=Color3.fromRGB(0,210,130) dotC=Color3.fromRGB(0,210,130) stTxt="GILIRAN KAMU"
    else barC=Color3.fromRGB(0,160,220) dotC=Color3.fromRGB(0,160,220) stTxt="Menunggu..." end
    pcall(function() MON.statusBar.BackgroundColor3=barC end)
    pcall(function() MON.sbFix.BackgroundColor3=barC end)
    pcall(function() MON.dot.BackgroundColor3=dotC end)
    pcall(function() MON.valStatus.Text=stTxt MON.valStatus.TextColor3=barC end)
    pcall(function() MON.valPrefix.Text=S.Prefix~="-" and S.Prefix:upper() or "—" end)
    pcall(function() MON.valSugg.Text=S.Suggestion~="-" and S.Suggestion:upper() or "—" end)
    pcall(function() MON.valWord.Text=S.CurrentWord~="-" and S.CurrentWord:upper() or "—" end)
    pcall(function() MON.pillTotal.Text=tostring(S.Terpakai) end)
    pcall(function() MON.pillBenar.Text="✓"..S.Benar end)
    pcall(function() MON.pillSalah.Text="✗"..S.Salah end)
    pcall(function() MON.valDB.Text=kbbiLoaded and totalWords.." kata" or "loading..." end)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SK MANUAL GUI  —  "Awalan: X"
-- Search bar, scrollable word list, badge huruf akhir, SENT+PILIH
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local MAN={}
local manPrefix=""   

local function rebuildList(prefix)
    if not MAN.scroll then return end
    -- Hapus rows lama
    for _,c in ipairs(MAN.scroll:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
    end
    if not kbbiLoaded then
        MAN.footer.Text="KBBI belum siap..." MAN.scroll.CanvasSize=UDim2.new(0,0,0,0) return
    end
    if not prefix or #prefix<1 then
        MAN.footer.Text="Ketik awalan untuk mencari" MAN.scroll.CanvasSize=UDim2.new(0,0,0,0) return
    end

    local words=getWordList(prefix,50)
    if #words==0 then
        local el=Instance.new("TextLabel",MAN.scroll)
        el.Size=UDim2.new(1,0,0,40) el.BackgroundTransparency=1
        el.Text='Tidak ada kata "'..prefix:upper()..'"'
        el.TextColor3=Color3.fromRGB(80,100,140) el.TextSize=11 el.Font=Enum.Font.Gotham
        MAN.footer.Text="0 kata" MAN.scroll.CanvasSize=UDim2.new(0,0,0,44) return
    end

    for idx, word in ipairs(words) do
        local diffTxt,diffBg,diffFg=getDiff(word)
        local lastCh=word:sub(-1):upper()

        -- ── Item row ──
        local row=Instance.new("Frame",MAN.scroll)
        row.Name="row"..idx row.LayoutOrder=idx
        row.Size=UDim2.new(1,-2,0,46)
        row.BackgroundColor3=Color3.fromRGB(16,20,34)
        row.BackgroundTransparency=0.05 row.BorderSizePixel=0
        Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)

        -- Left stripe (difficulty color)
        local stripe=Instance.new("Frame",row)
        stripe.Size=UDim2.new(0,3,0.65,0) stripe.Position=UDim2.new(0,0,0.175,0)
        stripe.BackgroundColor3=diffBg stripe.BorderSizePixel=0
        Instance.new("UICorner",stripe).CornerRadius=UDim.new(1,0)

        -- Kata (bold, warna dan tanda sesuai difficulty)
        local wordLbl=Instance.new("TextLabel",row)
        wordLbl.Size=UDim2.new(0,110,0,20) wordLbl.Position=UDim2.new(0,10,0,5)
        wordLbl.BackgroundTransparency=1
        wordLbl.Text=diffTxt=="HARD" and (word.." *") or word
        wordLbl.TextColor3=diffTxt=="HARD" and Color3.fromRGB(255,100,100)
            or diffTxt=="NORMAL" and Color3.fromRGB(255,200,70)
            or Color3.fromRGB(80,220,120)
        wordLbl.TextSize=12
        wordLbl.Font=Enum.Font.GothamBold wordLbl.TextXAlignment=Enum.TextXAlignment.Left

        -- Sub info: "X huruf | DIFFICULTY"
        local infoBase=Instance.new("TextLabel",row)
        infoBase.Size=UDim2.new(0,55,0,13) infoBase.Position=UDim2.new(0,10,0,26)
        infoBase.BackgroundTransparency=1 infoBase.Text=#word.." huruf  |  "
        infoBase.TextColor3=Color3.fromRGB(80,95,130) infoBase.TextSize=9
        infoBase.Font=Enum.Font.Gotham infoBase.TextXAlignment=Enum.TextXAlignment.Left

        -- Difficulty badge inline
        local dbadge=Instance.new("Frame",row)
        dbadge.Size=UDim2.new(0,46,0,13) dbadge.Position=UDim2.new(0,63,0,27)
        dbadge.BackgroundColor3=diffBg dbadge.BackgroundTransparency=0.55 dbadge.BorderSizePixel=0
        Instance.new("UICorner",dbadge).CornerRadius=UDim.new(0,4)
        local dTxt=Instance.new("TextLabel",dbadge)
        dTxt.Size=UDim2.new(1,0,1,0) dTxt.BackgroundTransparency=1
        dTxt.Text=diffTxt dTxt.TextColor3=diffFg dTxt.TextSize=8 dTxt.Font=Enum.Font.GothamBold

        -- Huruf akhir badge (bulat)
        local lbadge=Instance.new("Frame",row)
        lbadge.Size=UDim2.new(0,22,0,22) lbadge.Position=UDim2.new(1,-112,0.5,-11)
        lbadge.BackgroundColor3=diffBg lbadge.BackgroundTransparency=0.5 lbadge.BorderSizePixel=0
        Instance.new("UICorner",lbadge).CornerRadius=UDim.new(1,0)
        local lTxt=Instance.new("TextLabel",lbadge)
        lTxt.Size=UDim2.new(1,0,1,0) lTxt.BackgroundTransparency=1
        lTxt.Text=lastCh lTxt.TextColor3=diffFg lTxt.TextSize=11 lTxt.Font=Enum.Font.GothamBold

        -- Tombol SENT
        local sentBtn=Instance.new("TextButton",row)
        sentBtn.Size=UDim2.new(0,44,0,22) sentBtn.Position=UDim2.new(1,-82,0.5,-11)
        sentBtn.BackgroundColor3=Color3.fromRGB(0,110,220) sentBtn.Text="SENT"
        sentBtn.TextColor3=Color3.fromRGB(255,255,255) sentBtn.TextSize=10
        sentBtn.Font=Enum.Font.GothamBold sentBtn.BorderSizePixel=0
        sentBtn.Active=true
        Instance.new("UICorner",sentBtn).CornerRadius=UDim.new(0,5)
        sentBtn.MouseEnter:Connect(function() sentBtn.BackgroundColor3=Color3.fromRGB(0,145,255) end)
        sentBtn.MouseLeave:Connect(function() sentBtn.BackgroundColor3=Color3.fromRGB(0,110,220) end)

        -- Tombol PILIH
        local pilihBtn=Instance.new("TextButton",row)
        pilihBtn.Size=UDim2.new(0,44,0,22) pilihBtn.Position=UDim2.new(1,-34,0.5,-11)
        pilihBtn.BackgroundColor3=Color3.fromRGB(20,135,55) pilihBtn.Text="PILIH"
        pilihBtn.TextColor3=Color3.fromRGB(255,255,255) pilihBtn.TextSize=10
        pilihBtn.Font=Enum.Font.GothamBold pilihBtn.BorderSizePixel=0
        pilihBtn.Active=true
        Instance.new("UICorner",pilihBtn).CornerRadius=UDim.new(0,5)
        pilihBtn.MouseEnter:Connect(function() pilihBtn.BackgroundColor3=Color3.fromRGB(30,175,70) end)
        pilihBtn.MouseLeave:Connect(function() pilihBtn.BackgroundColor3=Color3.fromRGB(20,135,55) end)

        -- Hover highlight row
        row.MouseEnter:Connect(function() row.BackgroundColor3=Color3.fromRGB(22,28,48) end)
        row.MouseLeave:Connect(function() row.BackgroundColor3=Color3.fromRGB(16,20,34) end)

        -- === SENT logic ===
        local capturedWord=word
        sentBtn.MouseButton1Down:Connect(function()
            if not isMyTurn() then
                WindUI:Notify({Title="Bukan giliran!",Content="Tunggu giliran dulu.",Icon="alert-circle",Duration=2}) return
            end
            if S.Busy then return end
            S.Busy=true
            task.spawn(function()
                local sbefore=getWordServerText()
                local ok=typeAndSubmit(capturedWord,manPrefix)
                if not ok then S.Busy=false return end
                local el2=0; local acc=false
                while el2<2.0 do
                    task.wait(0.1); el2=el2+0.1
                    if not isMyTurn() then acc=true break end
                    local cur=getWordServerText()
                    if cur~="" and cur~=sbefore then acc=true break end
                end
                if acc then
                    S.UsedWords[capturedWord]=true S.CurrentWord=capturedWord
                    S.Terpakai=S.Terpakai+1 S.Benar=S.Benar+1
                    S.Suggestion=findBest(capturedWord:sub(-1),nil) or "-"
                    WindUI:Notify({Title="✓ "..capturedWord:upper(),Content="Terkirim!",Icon="check",Duration=2})
                    -- Tandai row sebagai terpakai (redup)
                    pcall(function()
                        row.BackgroundColor3=Color3.fromRGB(10,30,15)
                        wordLbl.TextColor3=Color3.fromRGB(40,100,60)
                        sentBtn.BackgroundColor3=Color3.fromRGB(30,60,30)
                        sentBtn.Text="✓" sentBtn.Active=false pilihBtn.Active=false
                    end)
                else
                    S.UsedWords[capturedWord]=true S.Salah=S.Salah+1
                    WindUI:Notify({Title="✗ Ditolak",Content=capturedWord:upper().." tidak diterima.",Icon="alert-circle",Duration=2})
                    pcall(function()
                        row.BackgroundColor3=Color3.fromRGB(35,10,10)
                        wordLbl.TextColor3=Color3.fromRGB(160,60,60)
                    end)
                end
                task.wait(0.3); S.Busy=false
            end)
        end)

        -- === PILIH logic: highlight saja, tidak kirim ===
        pilihBtn.MouseButton1Down:Connect(function()
            -- Reset highlight row lain
            for _,c in ipairs(MAN.scroll:GetChildren()) do
                if c:IsA("Frame") and c~=row then
                    pcall(function() c.BackgroundColor3=Color3.fromRGB(16,20,34) end)
                    pcall(function()
                        local wl=c:FindFirstChildWhichIsA("TextLabel")
                        if wl then wl.TextColor3=Color3.fromRGB(80,220,120) end
                    end)
                end
            end
            row.BackgroundColor3=Color3.fromRGB(15,42,25)
            local pstroke=row:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke",row)
            pstroke.Color=Color3.fromRGB(30,200,100) pstroke.Thickness=1 pstroke.Transparency=0.25
            S.Suggestion=capturedWord
            WindUI:Notify({Title="Dipilih: "..capturedWord:upper(),Content="Kata ini siap diketik",Icon="check",Duration=2})
        end)
    end

    -- Update canvas size
    task.wait()
    local h=MAN.listLayout.AbsoluteContentSize.Y+10
    MAN.scroll.CanvasSize=UDim2.new(0,0,0,h)
    -- Update canvas size setelah layout settle
    task.spawn(function()
        task.wait(0.05)
        if MAN.listLayout then
            local h=MAN.listLayout.AbsoluteContentSize.Y+10
            if MAN.scroll then MAN.scroll.CanvasSize=UDim2.new(0,0,0,h) end
        end
    end)
    MAN.footer.Text=#words.." kata ditemukan"
end

local function buildManual()
    local old=LocalPlayer.PlayerGui:FindFirstChild("VHManual")
    if old then old:Destroy() end

    local sg=Instance.new("ScreenGui")
    sg.Name="VHManual" sg.ResetOnSpawn=false sg.DisplayOrder=21
    sg.ZIndexBehavior=Enum.ZIndexBehavior.Global
    sg.Parent=LocalPlayer:WaitForChild("PlayerGui")

    local panel=Instance.new("Frame",sg)
    panel.Name="Panel"
    panel.Size=UDim2.new(0,262,0,305)
    panel.Position=UDim2.new(0,6,0,50)
    panel.BackgroundColor3=Color3.fromRGB(11,14,24)
    panel.BackgroundTransparency=0 panel.BorderSizePixel=0
    panel.Active=true panel.Draggable=true
    Instance.new("UICorner",panel).CornerRadius=UDim.new(0,12)
    local pst=Instance.new("UIStroke",panel)
    pst.Color=Color3.fromRGB(30,70,130) pst.Thickness=1 pst.Transparency=0.4

    -- ── Header ──
    local hdr=Instance.new("Frame",panel)
    hdr.Size=UDim2.new(1,0,0,44) hdr.BackgroundColor3=Color3.fromRGB(8,11,20) hdr.BorderSizePixel=0
    Instance.new("UICorner",hdr).CornerRadius=UDim.new(0,12)
    local hfix=Instance.new("Frame",hdr)
    hfix.Size=UDim2.new(1,0,0,12) hfix.Position=UDim2.new(0,0,1,-12)
    hfix.BackgroundColor3=Color3.fromRGB(8,11,20) hfix.BorderSizePixel=0


    -- Title "SK MANUAL"
    local htitle=Instance.new("TextLabel",hdr)
    htitle.Size=UDim2.new(0,130,1,0) htitle.Position=UDim2.new(0,14,0,0) htitle.BackgroundTransparency=1
    htitle.Text="SK MANUAL" htitle.TextColor3=Color3.fromRGB(255,255,255) htitle.TextSize=15
    htitle.Font=Enum.Font.GothamBold htitle.TextXAlignment=Enum.TextXAlignment.Left

    -- "Pilih kata..."
    MAN.pilihLabel=Instance.new("TextLabel",hdr)
    MAN.pilihLabel.Size=UDim2.new(0,100,1,0) MAN.pilihLabel.Position=UDim2.new(0,135,0,0)
    MAN.pilihLabel.BackgroundTransparency=1 MAN.pilihLabel.Text="Pilih kata..."
    MAN.pilihLabel.TextColor3=Color3.fromRGB(60,100,160) MAN.pilihLabel.TextSize=10
    MAN.pilihLabel.Font=Enum.Font.Gotham MAN.pilihLabel.TextXAlignment=Enum.TextXAlignment.Right

    -- Close
    local cb=Instance.new("TextButton",hdr)
    cb.Size=UDim2.new(0,22,0,22) cb.Position=UDim2.new(1,-28,0.5,-11)
    cb.BackgroundColor3=Color3.fromRGB(22,25,40) cb.Text="✕"
    cb.TextColor3=Color3.fromRGB(100,120,160) cb.TextSize=11
    cb.Font=Enum.Font.GothamBold cb.BorderSizePixel=0
    cb.Active=true
    Instance.new("UICorner",cb).CornerRadius=UDim.new(0,6)
    cb.MouseButton1Click:Connect(function() sg.Enabled=false S.ShowManual=false end)
    cb.MouseEnter:Connect(function() cb.BackgroundColor3=Color3.fromRGB(180,40,40) cb.TextColor3=Color3.fromRGB(255,255,255) end)
    cb.MouseLeave:Connect(function() cb.BackgroundColor3=Color3.fromRGB(22,25,40) cb.TextColor3=Color3.fromRGB(100,120,160) end)

    -- ── "Awalan: X" ──
    MAN.awalanLabel=Instance.new("TextLabel",panel)
    MAN.awalanLabel.Size=UDim2.new(1,-20,0,18) MAN.awalanLabel.Position=UDim2.new(0,14,0,48)
    MAN.awalanLabel.BackgroundTransparency=1 MAN.awalanLabel.Text="Awalan: —"
    MAN.awalanLabel.TextColor3=Color3.fromRGB(140,180,255) MAN.awalanLabel.TextSize=11
    MAN.awalanLabel.Font=Enum.Font.GothamBold MAN.awalanLabel.TextXAlignment=Enum.TextXAlignment.Left

    -- ── Mode filter: Semua / Mudah / Normal / Hard ──
    local modeFrame=Instance.new("Frame",panel)
    modeFrame.Size=UDim2.new(1,-20,0,22) modeFrame.Position=UDim2.new(0,10,0,70)
    modeFrame.BackgroundTransparency=1 modeFrame.BorderSizePixel=0
    local mll=Instance.new("UIListLayout",modeFrame)
    mll.FillDirection=Enum.FillDirection.Horizontal mll.Padding=UDim.new(0,3)
    local modeBtns={}
    local mClr={semua=Color3.fromRGB(40,70,150),mudah=Color3.fromRGB(18,100,38),normal=Color3.fromRGB(130,80,0),hard=Color3.fromRGB(150,18,18)}
    local mDef=Color3.fromRGB(22,26,44)
    for _,md in ipairs({{"Mudah","mudah"},{"Hard","hard"}}) do
        local lbl,key=md[1],md[2]
        local mb=Instance.new("TextButton",modeFrame)
        mb.Size=UDim2.new(0.48,0,1,0) mb.BackgroundColor3=(key=="mudah") and mClr[key] or mDef
        mb.BorderSizePixel=0 mb.Text=lbl mb.TextColor3=Color3.fromRGB(210,220,255)
        mb.TextSize=10 mb.Font=Enum.Font.GothamBold
        mb.Active=true
        Instance.new("UICorner",mb).CornerRadius=UDim.new(0,4)
        modeBtns[key]=mb
        mb.MouseButton1Click:Connect(function()
            S_ManualMode=key
            for k,b in pairs(modeBtns) do b.BackgroundColor3=(k==key) and mClr[k] or mDef end
            if manPrefix~="" then task.spawn(function() rebuildList(manPrefix) end) end
        end)
    end

    -- ── Search bar ──
    local sbg=Instance.new("Frame",panel)
    sbg.Size=UDim2.new(1,-20,0,32) sbg.Position=UDim2.new(0,10,0,96)
    sbg.BackgroundColor3=Color3.fromRGB(18,22,38) sbg.BorderSizePixel=0
    Instance.new("UICorner",sbg).CornerRadius=UDim.new(0,8)
    local sbst=Instance.new("UIStroke",sbg)
    sbst.Color=Color3.fromRGB(40,80,150) sbst.Thickness=1 sbst.Transparency=0.6

    local sbox=Instance.new("TextBox",sbg)
    sbox.Size=UDim2.new(1,-16,1,-4) sbox.Position=UDim2.new(0,10,0,2)
    sbox.BackgroundTransparency=1 sbox.Text=""
    sbox.PlaceholderText="Cari kata... (ketik awalan)"
    sbox.PlaceholderColor3=Color3.fromRGB(60,80,130)
    sbox.TextColor3=Color3.fromRGB(200,220,255) sbox.TextSize=11
    sbox.Font=Enum.Font.Gotham sbox.TextXAlignment=Enum.TextXAlignment.Left
    sbox.ClearTextOnFocus=false
    sbox.Active=true sbox.ZIndex=5
    sbg.ZIndex=5
    MAN.searchBox=sbox

    -- ── Scrolling list ──
    local scroll=Instance.new("ScrollingFrame",panel)
    scroll.Size=UDim2.new(1,-8,1,-138) scroll.Position=UDim2.new(0,4,0,132)
    scroll.BackgroundTransparency=1 scroll.BorderSizePixel=0
    scroll.ZIndex=5
    scroll.ScrollBarThickness=3 scroll.ScrollBarImageColor3=Color3.fromRGB(40,120,220)
    scroll.ScrollBarImageTransparency=0.4 scroll.CanvasSize=UDim2.new(0,0,0,0)
    MAN.scroll=scroll

    local ll=Instance.new("UIListLayout",scroll)
    ll.SortOrder=Enum.SortOrder.LayoutOrder ll.Padding=UDim.new(0,4)
    MAN.listLayout=ll
    local lpad=Instance.new("UIPadding",scroll)
    lpad.PaddingLeft=UDim.new(0,3) lpad.PaddingRight=UDim.new(0,3) lpad.PaddingTop=UDim.new(0,3)

    -- ── Footer (jumlah kata) ──
    MAN.footer=Instance.new("TextLabel",panel)
    MAN.footer.Size=UDim2.new(1,-16,0,14) MAN.footer.Position=UDim2.new(0,8,1,-16)
    MAN.footer.BackgroundTransparency=1 MAN.footer.Text=""
    MAN.footer.TextColor3=Color3.fromRGB(40,60,100) MAN.footer.TextSize=9
    MAN.footer.Font=Enum.Font.Gotham MAN.footer.TextXAlignment=Enum.TextXAlignment.Right

    MAN.sg=sg MAN.panel=panel

    -- Search hook
    sbox:GetPropertyChangedSignal("Text"):Connect(function()
        local q=sbox.Text:lower():gsub("[^a-z]","")
        if #q>=1 then
            manPrefix=q
            MAN.awalanLabel.Text="Awalan: "..q:upper()
            task.spawn(function() rebuildList(q) end)
        else
            MAN.awalanLabel.Text="Awalan: —"
        end
    end)
end

local function openManual(prefix)
    if not MAN.sg then buildManual() end
    MAN.sg.Enabled=true
    if prefix and #prefix>=1 then
        manPrefix=prefix
        MAN.awalanLabel.Text="Awalan: "..prefix:upper()
        if MAN.searchBox then MAN.searchBox.Text=prefix end
        task.spawn(function() rebuildList(prefix) end)
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- WINDUI
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Win=WindUI:CreateWindow({
    Title="Victoria Hub", Icon="rbxassetid://96751490485303",
    Author="Sambung Kata", Folder="VICTORIA_HUB",
    Transparent=true, Size=UDim2.fromOffset(240,300),
    HasOutline=true, SideBarWidth=160,
})
Win:EditOpenButton({
    Title="Victoria Hub", Icon="rbxassetid://96751490485303",
    CornerRadius=UDim.new(0,16), StrokeThickness=2,
    Color=ColorSequence.new(Color3.fromHex("#0066ff"),Color3.fromHex("#003399")),
    OnlyMobile=true, Enabled=false, Draggable=false,
})
Win:Tag({Title="V29.0",Color=Color3.fromRGB(255,255,255),Radius=17})
local executorName=identifyexecutor and identifyexecutor() or "Unknown"
local executorColor=Color3.fromRGB(200,200,200)
local execMap={flux="#30ff6a",delta="#38b6ff",arceus="#a03cff",krampus="#ff3838",oxygen="#ff3838",volcano="#ff8c00",synapse="#ffd700",krypton="#ffd700",wave="#00e5ff",zenith="#ff00ff",seliware="#00ffa2",krnl="#1e90ff",trigon="#ff007f",nihon="#8a2be2",celery="#4caf50",lunar="#8080ff",valyse="#ff1493",vega="#4682b4",electron="#7fffd4",awp="#ff005e",bunni="#ff69b4"}
for k,v in pairs(execMap) do
    if executorName:lower():find(k) then executorColor=Color3.fromHex(v) break end
end
Win:Tag({Title="EXECUTOR | "..executorName,Icon="github",Color=executorColor,Radius=0})

local Tab1=Win:Tab({Title="Main",Icon="gamepad-2",Box=true,BoxBorder=true})

local actSec=Tab1:Section({Title="Activities Monitoring",Icon="activity",Box=true,BoxBorder=true,Opened=false})
ParaStatus=actSec:Paragraph({
    Title="SYSTEM",
    Desc="Status: -\nDatabase: "..kbbiStatus.."\nPrefix: -\nSuggestion: -\nTerpakai: 0\nBenar: 0  Salah: 0",
})
actSec:Button({
    Title="Reset Words",Icon="refresh-cw",Justify="Center",
    Callback=function()
        S.UsedWords={} S.LastSubmit="" S.Terpakai=0
        S.CurrentWord="-" S.Benar=0 S.Salah=0 S.Busy=false S.Suggestion="-"
        WindUI:Notify({Title="Reset",Content="Siap ronde baru!",Icon="check",Duration=2})
    end,
})
actSec:Toggle({
    Title="Monitor GUI",Desc="Panel compact pojok kanan bawah",Icon="monitor",Value=false,
    Callback=function(v)
        S.ShowMonitor=v
        if v then
            if not MON.sg then buildMonitor() end
            MON.sg.Enabled=true updateMonitor()
        else if MON.sg then MON.sg.Enabled=false end end
    end,
})

local modeSec=Tab1:Section({Title="Auto Feature",Icon="power",Box=true,BoxBorder=true,Opened=false})
modeSec:Toggle({
    Title="Auto Answer",Desc="Auto jawab + koreksi jika ditolak server",Icon="play",Value=false,
    Callback=function(v)
        S.AutoAnswer=v S.Busy=false
        WindUI:Notify({Title=v and "Auto SK ON" or "Auto SK OFF",Content=v and "Siap!" or "Stop.",Icon=v and "play" or "square",Duration=2})
    end,
})
modeSec:Slider({Title="Answer Delay",Desc="Jeda sebelum mulai ketik",Step=1,Value={Min=1,Max=50,Default=15},Callback=function(v) S.Delay=v/10 end})
modeSec:Slider({Title="Typing Speed",Desc="Kecepatan klik per huruf",Step=1,Value={Min=3,Max=50,Default=30},Callback=function(v) S.Speed=v/100 end})

-- SK Manual
local manSec=Tab1:Section({Title="SK Manual",Icon="list",Box=true,BoxBorder=true,Opened=false})
manSec:Toggle({
    Title="Panel SK Manual",Desc="List kata KBBI per prefix + SENT/PILIH",Icon="list",Value=false,
    Callback=function(v)
        S.ShowManual=v
        if v then
            openManual(S.Prefix~="-" and S.Prefix or "")
        else
            if MAN.sg then MAN.sg.Enabled=false end
        end
    end,
})
manSec:Paragraph({
    Title="Cara pakai",
    Desc="Buka panel → ketik awalan di search\nSENT = kirim via auto-type\nPILIH = highlight kata pilihan",
})

local kbbiSec=Tab1:Section({Title="KBBI Word Source",Icon="database",Box=true,BoxBorder=true,Opened=false})
ParaDB=kbbiSec:Paragraph({Title="KBBI Status",Desc="Source: GitHub (VictoriaHub)\nTotal: "..totalWords.." Words\nStatus: "..kbbiStatus})

local raritySec=Tab1:Section({Title="Letter Rarity",Icon="book-open",Box=true,BoxBorder=true,Opened=false})
ParaRarity=raritySec:Paragraph({Title="Frekuensi Huruf",Desc=getRarityText()})

local Tab2=Win:Tab({Title="Settings",Icon="settings",Box=true,BoxBorder=true})
local dbgSec=Tab2:Section({Title="Debug",Icon="terminal",Box=true,BoxBorder=true,Opened=false})
dbgSec:Toggle({
    Title="Debug Mode",Desc="Print info ke F9",Value=false,
    Callback=function(v) S.Debug=v WindUI:Notify({Title="Debug",Content=v and "ON" or "OFF",Icon="terminal",Duration=2}) end,
})

local prevTurn=false
local tStat=0

task.spawn(function()
    while true do
        task.wait(0.5)
        local ws=getWordSubmit()
        if ws then
            local _dbt=nil
            local function onSlotChanged()
                if _dbt then task.cancel(_dbt) end
                _dbt=task.delay(0.15,function()
                    _dbt=nil
                    if not kbbiLoaded then return end
                    local text=getWordSubmitText()
                    local newPfx=""
                    if text and #text>0 then
                        newPfx=text
                    else
                        local p=getWordServerText()
                        if p~="" then newPfx=p end
                    end
                    if newPfx~="" and newPfx~=S.Prefix then
                        S.Prefix=newPfx
                        S.Suggestion=findBest(newPfx,nil) or "-"
                        if S.ShowManual and MAN.sg and MAN.sg.Enabled and newPfx~=manPrefix then
                            manPrefix=newPfx
                            if MAN.awalanLabel then MAN.awalanLabel.Text="Awalan: "..newPfx:upper() end
                            if MAN.searchBox then MAN.searchBox.Text=newPfx end
                            task.spawn(function() rebuildList(newPfx) end)
                        end
                    end
                end)
            end
            
            for _,child in ipairs(ws:GetChildren()) do
                if child:IsA("TextLabel") then
                    child:GetPropertyChangedSignal("Text"):Connect(onSlotChanged)
                end
            end
            
            ws.DescendantAdded:Connect(function(child)
                if child:IsA("TextLabel") then
                    child:GetPropertyChangedSignal("Text"):Connect(onSlotChanged)
                end
            end)
            onSlotChanged()
            break
        end
    end
end)


local _lastHurufPfx=""
task.spawn(function()
    while true do
        task.wait(0.3)
        if kbbiLoaded then
            local pg=LocalPlayer:FindFirstChild("PlayerGui")
            if pg then
                for _,v in ipairs(pg:GetDescendants()) do
                    if v:IsA("TextLabel") and v.Visible and v.Text and v.Text:find("Hurufnya adalah") then
                        for _,sib in ipairs(v.Parent:GetChildren()) do
                            if sib:IsA("TextLabel") and sib~=v and sib.Visible then
                                local t=sib.Text:gsub("%s+",""):upper()
                                if t:match("^[A-Z]+$") and #t>=1 and #t<=4 and t~=_lastHurufPfx then
                                    _lastHurufPfx=t
                                    local raw=t:lower()
                                    if raw~=S.Prefix then
                                        S.Prefix=raw
                                        S.Suggestion=findBest(raw,nil) or "-"
                                    end
                                    if S.ShowManual and MAN.sg and MAN.sg.Enabled and raw~=manPrefix then
                                        manPrefix=raw
                                        if MAN.awalanLabel then MAN.awalanLabel.Text="Awalan: "..raw:upper() end
                                        if MAN.searchBox then MAN.searchBox.Text=raw end
                                        task.spawn(function() rebuildList(raw) end)
                                    end
                                    break
                                end
                            end
                        end
                        break
                    end
                end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function(dt)
    tStat=tStat+dt


    local myTurn=isMyTurn()
    if myTurn and not prevTurn then
        prevTurn=true S.Busy=false S.LastSubmit=""
        local p=getWordServerText()
        if p~="" and p~=S.Prefix then
            S.Prefix=p; S.Suggestion=findBest(p,nil) or "-"
        end
        if S.Debug then print("[SK] GILIRAN! Prefix='"..S.Prefix.."'") end
        -- Auto-update manual panel
        if S.ShowManual and MAN.sg and MAN.sg.Enabled and S.Prefix~="-" and S.Prefix~=manPrefix then
            manPrefix=S.Prefix
            if MAN.awalanLabel then MAN.awalanLabel.Text="Awalan: "..S.Prefix:upper() end
            if MAN.searchBox then MAN.searchBox.Text=S.Prefix end
            task.spawn(function() rebuildList(S.Prefix) end)
        end
        if S.AutoAnswer then doAnswer() end
    end
    if not myTurn and prevTurn then prevTurn=false S.Busy=false end

 
    if tStat>=0.4 then
        tStat=0
        task.spawn(function()
            local mt=isMyTurn()
            local st=not S.AutoAnswer and "Stop" or mt and "Giliran kamu!" or "Menunggu lawan..."
            pcall(function() ParaStatus:SetDesc(
                "Status: "..st.."\nDatabase: "..kbbiStatus..
                "\nPrefix: "..(S.Prefix~="-" and S.Prefix:upper() or "-")..
                "\nSuggestion: "..(S.Suggestion~="-" and S.Suggestion:upper() or "-")..
                "\nTerpakai: "..S.Terpakai.."\nBenar: "..S.Benar.."  Salah: "..S.Salah
            ) end)
            pcall(function() ParaDB:SetDesc(
                "Source: GitHub (VictoriaHub)\nTotal: "..totalWords.." Words\nStatus: "..kbbiStatus
            ) end)
            if kbbiLoaded then pcall(function() ParaRarity:SetDesc(getRarityText()) end) end
            if S.ShowMonitor then updateMonitor() end
        end)
    end
end)

-- REMOTE LISTENERS
if R_UsedWordWarn then
    R_UsedWordWarn.OnClientEvent:Connect(function(a1)
        local w=type(a1)=="string" and a1:lower():gsub("[^a-z]","") or ""
        if #w>1 then S.UsedWords[w]=true end
    end)
end
if R_PlayerCorrect then
    R_PlayerCorrect.OnClientEvent:Connect(function()
        S.LastSubmit="" S.Busy=false
    end)
end

--OPEN/CLOSE WINDOWS UI

_G.UserInputService = game:GetService("UserInputService")
_G.RunService = game:GetService("RunService")
_G.PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

_G.uisConnection = nil
_G.dragging = false
_G.dragInput = nil
_G.dragStart = nil
_G.startPos = nil

_G.CreateFloatingIcon = function()
    local existingGui = _G.PlayerGui:FindFirstChild("CustomFloatingIcon_RockHub")
    if existingGui then existingGui:Destroy() end

    local FloatingIconGui = Instance.new("ScreenGui")
    FloatingIconGui.Name = "CustomFloatingIcon_RockHub"
    FloatingIconGui.DisplayOrder = 999
    FloatingIconGui.ResetOnSpawn = false

    local FloatingFrame = Instance.new("Frame")
    FloatingFrame.Name = "FloatingFrame"
    FloatingFrame.Position = UDim2.new(0, 50, 0.4, 0)
    FloatingFrame.Size = UDim2.fromOffset(55, 55)
    FloatingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    FloatingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    FloatingFrame.BorderSizePixel = 0
    FloatingFrame.Parent = FloatingIconGui

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromHex("#000000")
    stroke.Thickness = 2
    stroke.Parent = FloatingFrame

    Instance.new("UICorner", FloatingFrame).CornerRadius = UDim.new(0, 12)

    local IconImage = Instance.new("ImageLabel")
    IconImage.Image = "rbxassetid://96751490485303"
    IconImage.BackgroundTransparency = 1
    IconImage.Size = UDim2.new(1, -4, 1, -4)
    IconImage.Position = UDim2.fromScale(0.5, 0.5)
    IconImage.AnchorPoint = Vector2.new(0.5, 0.5)
    IconImage.Parent = FloatingFrame

    Instance.new("UICorner", IconImage).CornerRadius = UDim.new(0, 10)

    FloatingIconGui.Parent = _G.PlayerGui
    return FloatingIconGui, FloatingFrame
end

_G.SetupFloatingIcon = function(FloatingIconGui, FloatingFrame)
    if _G.uisConnection then
        _G.uisConnection:Disconnect()
        _G.uisConnection = nil
    end

    local didMove = false

    local function update(input)
        local delta = input.Position - _G.dragStart
        FloatingFrame.Position = UDim2.new(
            _G.startPos.X.Scale,
            _G.startPos.X.Offset + delta.X,
            _G.startPos.Y.Scale,
            _G.startPos.Y.Offset + delta.Y
        )
    end

    FloatingFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

            _G.dragging = true
            _G.dragStart = input.Position
            _G.startPos = FloatingFrame.Position
            didMove = false

            -- Connection untuk detect mouse release
            local releaseConnection
            releaseConnection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    _G.dragging = false

                    -- CLICK (NOT DRAG) → TOGGLE UI
                    if not didMove then
                        if Window and Window.Toggle then
                            Window:Toggle()
                        end
                    end

                    releaseConnection:Disconnect()
                end
            end)
        end
    end)

    FloatingFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            _G.dragInput = input
        end
    end)

    _G.uisConnection = _G.UserInputService.InputChanged:Connect(function(input)
        if input == _G.dragInput and _G.dragging then
            if (input.Position - _G.dragStart).Magnitude > 5 then
                didMove = true
            end
            update(input)
        end
    end)
end

_G.InitializeIcon = function()
    if not game.Players.LocalPlayer.Character then
        game.Players.LocalPlayer.CharacterAdded:Wait()
    end

    local gui, frame = _G.CreateFloatingIcon()
    _G.SetupFloatingIcon(gui, frame)
end

game.Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    _G.InitializeIcon()
end)

_G.InitializeIcon()


WindUI:Notify({Title="Auto SK v40.0",Content="Loading KBBI...",Icon="zap",Duration=3})
