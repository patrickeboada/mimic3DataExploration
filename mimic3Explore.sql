--The primary goal of my search through the database is to evaluate the population
--diversity and the most common disease or illness. With that information I will
--determine which types of pharmaceuticals or procedures were given to patients with
--frequently treated severe diseases.



--1: Data frame of linguistic diversity
SELECT language, count(language) AS language_frequency
FROM mimiciii.ADMISSIONS
GROUP BY language
ORDER BY count(language) DESC
LIMIT 100;

--2: Data frame of various cancer diagnosis
SELECT admissions.diagnosis, count(admissions.diagnosis)
FROM mimiciii.ADMISSIONS
WHERE admissions.diagnosis LIKE '%CANCER%'
GROUP BY admissions.diagnosis
ORDER BY count(admissions.diagnosis) DESC;


--3 Determine the length for the textual notes taken on patients 
SELECT admissions.HADM_ID, patients.dod_hosp, LENGTH(noteevents.TEXT)
FROM mimiciii.NOTEEVENTS
	INNER JOIN mimiciii.ADMISSIONS
		ON mimiciii.admissions.HADM_ID = mimiciii.noteevents.HADM_ID
	INNER JOIN mimiciii.PATIENTS
		ON mimiciii.admissions.subject_id = mimiciii.patients.subject_id
WHERE patients.dod_hosp IS NOT NULL
LIMIT 50;




--4: Determine average age for patients who died in hospital
SELECT AVG(patients.dod - patients.dob) AS AVG_DECEASED_PATIENT_AGE
FROM mimiciii.PATIENTS;
--output is in days, average is ~92 years

--5: Change the casing from mixed lower and upper to all upper case letters.
SELECT admissions.subject_id, UPPER(SUBSTR(noteevents.TEXT,0, 100)) AS NOTES
FROM mimiciii.ADMISSIONS
	INNER JOIN mimiciii.NOTEEVENTS
		ON mimiciii.admissions.HADM_ID = mimiciii.noteevents.HADM_ID
WHERE admissions.diagnosis LIKE '%BLADDER%'
AND admissions.diagnosis LIKE '%CANCER%'
LIMIT 100;


--6: Search of patient's note events, with a ICD9 code for bladder cancer, along with associated subject_id and ICD9
SELECT SUBSTR(noteevents.TEXT,0, 100) AS NOTES, admissions.subject_id
FROM mimiciii.ADMISSIONS
	INNER JOIN mimiciii.NOTEEVENTS
		ON mimiciii.admissions.HADM_ID = mimiciii.noteevents.HADM_ID
	INNER JOIN mimiciii.diagnoses_icd
		ON mimiciii.admissions.HADM_ID = mimiciii.diagnoses_icd.HADM_ID
WHERE diagnoses_icd.ICD9_CODE = '1889'
LIMIT 100;


--7: Data frame for patients who died with lung cancer diagnosis, prescriptions and services
SELECT DISTINCT admissions.HADM_ID,prescriptions.DRUG_TYPE, prescriptions.DRUG_NAME_GENERIC, d_icd_procedures.LONG_TITLE AS ICD9_PROCEDURE, d_icd_procedures.ICD9_CODE 
FROM mimiciii.ADMISSIONS 
	INNER JOIN mimiciii.PRESCRIPTIONS 
		ON mimiciii.admissions.HADM_ID = mimiciii.prescriptions.HADM_ID
	INNER  JOIN mimiciii.PROCEDURES_ICD
		ON mimiciii.admissions.HADM_ID = mimiciii.PROCEDURES_ICD.HADM_ID
	INNER JOIN mimiciii.D_ICD_PROCEDURES
		ON mimiciii.PROCEDURES_ICD.ICD9_CODE = mimiciii.D_ICD_PROCEDURES.ICD9_CODE
WHERE admissions.diagnosis LIKE '%CANCER%'
AND admissions.diagnosis LIKE '%LUNG%'
AND admissions.ADMITTIME < admissions.DEATHTIME
GROUP BY admissions.HADM_ID, prescriptions.DRUG_TYPE, prescriptions.DRUG_NAME_GENERIC, d_icd_procedures.LONG_TITLE, d_icd_procedures.ICD9_CODE
ORDER BY admissions.HADM_ID DESC
LIMIT 100;




--8: Data Frame for lung cancer patients who have an infection in their lungs 
SELECT DISTINCT admissions.subject_id, admissions.HADM_ID, admissions.ADMITTIME, microbiologyevents.charttime, microbiologyevents.spec_type_desc, microbiologyevents.org_name
FROM mimiciii.ADMISSIONS 
	INNER JOIN mimiciii.PATIENTS
		ON mimiciii.admissions.subject_id = mimiciii.patients.subject_id
	INNER JOIN mimiciii.MICROBIOLOGYEVENTS
		ON mimiciii.patients.subject_id = mimiciii.microbiologyevents.subject_id
WHERE admissions.diagnosis LIKE '%CANCER%'
AND admissions.diagnosis LIKE '%LUNG%'
AND microbiologyevents.spec_type_desc = 'PLEURAL FLUID'
AND microbiologyevents.org_name IS NOT NULL
ORDER BY admissions.subject_id DESC;



--9: Patient's length of time in ICU with associate ICD9 title diagnosis and code. 
--Exclusion of premature babies given to focus results on adult population
SELECT admissions.HADM_ID, icustays.OUTTIME - icustays.INTIME AS ICUTIME, d_icd_diagnoses.LONG_TITLE AS ICD9_DIAGNOSIS, d_icd_diagnoses.ICD9_CODE
FROM mimiciii.ADMISSIONS
	INNER JOIN mimiciii.ICUSTAYS 
		ON mimiciii.admissions.HADM_ID = mimiciii.icustays.HADM_ID
	INNER JOIN mimiciii.diagnoses_icd
		ON mimiciii.admissions.HADM_ID = mimiciii.diagnoses_icd.HADM_ID
	INNER JOIN mimiciii.d_icd_diagnoses
		ON mimiciii.diagnoses_icd.ICD9_CODE = mimiciii.d_icd_diagnoses.ICD9_CODE
WHERE admissions.diagnosis !='NEWBORN' 
AND admissions.diagnosis != 'PREMATURITY'
AND admissions.diagnosis != 'EXTREME PREMATURITY'
AND icustays.OUTTIME - icustays.INTIME IS NOT NULL
ORDER BY icustays.OUTTIME - icustays.INTIME DESC
LIMIT 100;


--10: Number of patients undergoing a heart related procedure after experiencing a heart attack
SELECT COUNT(admissions.subject_id) AS Patients_with_Heart_Attack_Undergoing_Procedure, d_icd_procedures.LONG_TITLE AS ICD9_PROCEDURE
FROM mimiciii.ADMISSIONS 
	INNER JOIN mimiciii.PROCEDURES_ICD
		ON mimiciii.admissions.HADM_ID = mimiciii.PROCEDURES_ICD.HADM_ID
	INNER JOIN mimiciii.D_ICD_PROCEDURES
		ON mimiciii.PROCEDURES_ICD.ICD9_CODE = mimiciii.D_ICD_PROCEDURES.ICD9_CODE
WHERE admissions.diagnosis LIKE '%MYOCARDIAL%'
AND admissions.diagnosis LIKE '%INFARCTION%'
GROUP BY d_icd_procedures.LONG_TITLE
ORDER BY COUNT(admissions.subject_id) DESC
LIMIT 100;
