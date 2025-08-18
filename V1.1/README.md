# V1.1

---

This is the major assignment for the second semester of the freshman year, which was completed using MATLAB.

The pdf file is the corresponding project report. Personal information has been removed on the first page. Although it looks like an academic paper, it is actually quite far from that. Anyway, this is a very good exercise for using LaTeX.

---

I personally think this project has the following problems: 

1.  **The accuracy  of models is tested using augmented and preprocessed images, that is, using the training set as the test set, which is a rather big mistake. **In fact, due to the lack of data, I did not adopt the approach of dividing it into a training set, a validation set, and a test set. So essentially, the accuracy data in the report should be the accuracy of the training set and I had not tested the generalization ability of the model.
2.  **Extracting the features of images first and then conducting classification training is a traditional machine learning method, which makes the model have certain limitations to some extent. **The main reason for adopting this approach is to meet the requirements of the course, that is, to use the algorithms learned in class. Regardless of the performance of the model, this project has fulfilled the requirements of being a course assignment and the purpose of applying what has been learned. 

---

The accuracy rate of this version for its corresponding dataset (strictly speaking, the accuracy rate of the training set) is **58.6%** (the highest among the three models).
