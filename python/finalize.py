import pandas as pd
import json
import datetime as dt
import sys


def distance_to_dict(file):
    """
    Creates a dictionary from a pandas dataframe
    :param file: Sample SKA compare file (tsv)
    :return: A dictionary sorted by closest relatedness
    """
    df = pd.read_csv(f"{file}", sep="\t")
    df = df.sort_values('%ID of matching kmers', ascending=False)
    sorted_df = df.reset_index().to_dict()
    del sorted_df['index']
    return sorted_df


def metadata(file, parameters):
    """
    This function creates and returns a dictionary with metadata of the run
    :param parameters: A list with parameters
    :param file: Sample SKA compare file (tsv), to extract sample name
    :return: dictionary with metadata of the run
    """
    tree_type = "Maximum Likelihood"
    iterations = float(parameters[4])
    if parameters[5] == "true" and iterations > 0:
        tree_type = "Consensus tree"
    if iterations > 0 and iterations < 1000:
    	parameters[4] = "1000"
    return {
        "sample": file.strip('.tsv'),
        "Run date": str(dt.datetime.now()),
        "params": {
            "k-mer": parameters[0],
            "reads quality score": parameters[1],
            "read coverage": parameters[2],
            "alignment proportion": parameters[3],
            "tree iterations": parameters[4],
            "Tree type": tree_type
        }
    }


def jsonify(df, meta, save, file):
    """
    Write dictionaries to a json file.
    :param df: Sorted dataframe dictionary
    :param meta: Dictionary with metadata of sample run
    :param save: Path to save JSON in
    :param file: sample name used to name the JSON
    """
    final = {"metadata": meta, "distance": df}
    with open(f"{save}{file}.json", "w") as file:
        file.write(json.dumps(final))


def main():
    """
    Main function, note that most variables are called from commandline arguments
    sys.argv[1] is the tab-separeted ska compare file
    sys.argv[2] is the path to save the JSON to
    """
    file = sys.argv[1]
    save_location = sys.argv[2]
    df_dict = distance_to_dict(file)
    meta = metadata(file, sys.argv[3].split(","))
    jsonify(df_dict, meta, save_location, file.rstrip('.tsv'))


main()
