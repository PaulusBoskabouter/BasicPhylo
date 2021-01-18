import sys


def extract_template(path):
    """
    Extracts template string from reference_cluster.txt
    :param path: R folder path
    :return: Returns content of reference_cluster.txt
    """
    # Extract contents from template
    with open(f"{path}reference_cluster.txt", "r") as file:
        data = file.read()
        file.close()
        return data


def create_cluster_file(path, template, sample):
    """
    Write sapmle_cluster.txt with sample
    :param path: R folder to create text file into
    :param template: Template text from reference_cluster.txt
    :param sample: Sample name
    """
    with open(f"{path}sample_cluster.txt", "w") as file:
        file.write(template)
        file.write(f"{sample}\tSample\tSample\tmaroon1")
        file.close()


def main():
    """
    Called by: Python clustering.py Sample_name Path_to_R_folder
    Main function connects all functions, goal of this script is adding the sample names to a tab separated file
    """
    template = extract_template(sys.argv[2])
    create_cluster_file(sys.argv[2], template, sys.argv[1])


main()
