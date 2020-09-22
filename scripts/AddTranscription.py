import requests
import json
import os.path

headers = {'Content-type': 'application/json', 'Accept': 'application/json',
           'Authorization': 'Token ac4e7ccd26af1a474a56576907215fd8de59319f'}

base_url = 'https://www.escriptorium.fr/api/documents/'
document_nu = '30'
# first element (= part) in the document
element_nu = '9712'
transcription_url = base_url + document_nu + "/parts/" + element_nu + "/transcriptions/"
document_transcription_url = base_url + document_nu + "/transcriptions/"
# path to the folder with the transcriptions (as txt files); no slash "/" at the end
transcription_path = "C:/Users/User/Desktop"


# get all keys with a particular name in a dictionary object
def json_extract(obj, key):
    arr = []

    def extract(obj, arr, key):
        if isinstance(obj, dict):
            for k, v in obj.items():
                if isinstance(v, (dict, list)):
                    extract(v, arr, key)
                elif k == key:
                    arr.append(v)
        elif isinstance(obj, list):
            for item in obj:
                extract(item, arr, key)
        return arr

    values = extract(obj, arr, key)
    return values


print("> Searching document for elements ...")
part_list = [element_nu]
part_url = base_url + document_nu + "/parts/" + element_nu + "/"
error_log = []


def print_error_log():
    if len(error_log) > 0:
        print("ERROR LOG:")
        for e in error_log:
            print("> " + e)


# searches document for elements and adds them to part_list
def getParts(part_nu):
    iterate_parts_url = base_url + document_nu + "/parts/" + str(part_nu) + "/"
    req_parts = requests.get(iterate_parts_url, headers=headers).json()
    try:
        if not str(req_parts["next"]) == "None":
            part_nu = req_parts["next"]
            part_list.append(req_parts["next"])
            getParts(part_nu)
        else:
            return
    except KeyError:
        error_text = "ERROR: Did not find key 'next' in document " + str(document_nu) + " / Element: " + str(part_nu) + ".\n[Please make sure that element_nu is the number of the first part in the document.]"
        print(error_text)
        error_log.append(error_text)
        exit(1)


getParts(element_nu)
print("SUCCESS: Found " + str(len(part_list)) + " in document " + str(document_nu) + ".")


def readFile(path):
    f = open(path, "r", encoding="utf-8")
    return f.read()


for part in part_list:
    current_transcription_url = base_url + document_nu + "/parts/" + str(part) + "/transcriptions/"
    current_part_url = base_url + document_nu + "/parts/" + str(part) + "/"
    edit_part_url = "https://escriptorium.fr/document/" + document_nu + "/part/" + str(part) + "/edit/"
    print("> Trying to update the transcription @ " + "https://escriptorium.fr/document/" + document_nu + "/part/" + str(part) + "/edit/ ...")
    print("#####################################################################################################################")
    # read transcription
    text_lines = []
    req0 = requests.get(current_part_url, headers=headers).json()
    eScriptorium_name = req0["filename"]
    local_path = transcription_path + "/" + eScriptorium_name + ".txt"
    print("> Searching " + transcription_path + " for " + eScriptorium_name + ".txt ...")
    if os.path.exists(local_path):
        print("SUCCESS: Matching local transcription file found. Reading ...")
        print("> Reading local transcription file ...")
        text = readFile(local_path)
        text_lines = text.split("\n")
        print("SUCCESS: Local transcription lines were read.")
    else:
        error_text = "ERROR: No matching local transcription file found (Path: " + local_path + ").\n[Please make sure that the transcription_path is right and contains all correctly named txt files.]"
        print(error_text)
        error_log.append("@ " + edit_part_url + " " + error_text)
        user = input("> User input required (Y = yes / N = no, confirm with Enter): Would you like to skip the missing transcription (Y/N)?\nINPUT: ")
        if user == "Y":
            print("> Skipping the current part ...")
            print("#####################################################################################################################")
            continue
        else:
            print("> Stopping the program ...")
            print("#####################################################################################################################")
            print_error_log()
            exit(1)

    # get pks of transcription lines
    req = requests.get(current_transcription_url, headers=headers).json()
    transcription_pks = list(json_extract(req, "pk"))
    transcription_pks_index = 0
    transcription_line_pks = list(json_extract(req, "line"))

    # get line pks
    print("> Searching part " + str(part) + " for lines ...")
    req2 = requests.get(current_part_url + "lines/", headers=headers).json()
    line_pks = list(json_extract(req2, "pk"))
    if len(line_pks) != len(text_lines):
        if len(text_lines) > len(line_pks):
            error_text = "WARNING: The number of lines in the local transcription file is greater than the number of transcription lines!\n[Please check if lines are missing in the online transcription.]"
            print(error_text)
            error_log.append("@ " + edit_part_url + " " + error_text)
        else:
            error_text = "ERROR: The number of transcription lines does not equal the number of lines in the local transcription file."
            print(error_text)
            error_log.append("@ " + edit_part_url + " " + error_text)
            print("> Skipping the current part ...")
            print("#####################################################################################################################")
            continue
    else:
        print("SUCCESS: Found lines of part " + str(part) + " " + str(line_pks) + ".")

    # iterate through line PKs
    for i in range(len(line_pks)):
        # find out method
        if line_pks[i] in transcription_line_pks:
            method = "PUT"
        else:
            method = "POST"

        # update the transcription with the suiting method
        if method == "PUT":
            # ends with pk of the line line_transcription_url = "https://www.escriptorium.fr/api/documents/30/parts/9712/transcriptions/83326/"
            line_transcription_url = "https://www.escriptorium.fr/api/documents/" + document_nu + "/parts/" + str(part) + "/transcriptions/" + str(transcription_pks[transcription_pks_index]) + "/"
            # get current line content
            req = requests.get(line_transcription_url, headers=headers).json()
            # set new content
            req['content'] = text_lines[i]
            print("> Updating transcription using PUT @ transcription line " + str(transcription_pks[transcription_pks_index]) + " with the following text: " + str(text_lines[i]) + " ...")
            # put new content
            req2 = requests.put(line_transcription_url, headers=headers, data=json.dumps(req))
            if req2.status_code == 200:
                print("SUCCESS: Updated line " + str(transcription_pks[i]) + ".")
            else:
                error_text = "ERROR: HTTP-Code " + str(req2.status_code) + " after PUT on " + line_transcription_url + "."
                print(error_text)
                error_log.append(error_text)
            transcription_pks_index += 1
        if method == "POST":
            # GET manual transcription pk
            req = requests.get(document_transcription_url, headers=headers).json()
            manual_transcription_pk = req[0]["pk"]
            # POST
            data = {'line': line_pks[i], 'transcription': manual_transcription_pk, 'content': text_lines[i]}
            print("> Updating transcription using POST @ line pk " + str(line_pks[i]) + " with the following text: " + str(text_lines[i]) + " ...")
            req2 = requests.post(current_transcription_url, data=json.dumps(data), headers=headers)
            if req2.status_code == 201 or req2.status_code == 200:
                print("SUCCESS: Updated line " + str(line_pks[i]) + ".")
            else:
                error_text = "ERROR: HTTP-Code " + str(req2.status_code) + " after POST on " + current_transcription_url + "."
                print(error_text)
                error_log.append(error_text)
    print("[DONE]")
    print("#####################################################################################################################")
print_error_log()