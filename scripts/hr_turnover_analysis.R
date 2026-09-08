library(tidyverse)
library(randomForest)
library(pROC)
library(rpart)
library(rpart.plot)
if (!requireNamespace("corrplot", quietly = TRUE)) install.packages("corrplot")
library(corrplot)
if(!require(GGally)) install.packages("GGally")
library(GGally)
library(caret)
library(plotly)

hr <- read_csv('./kaggle_hr_analytics.csv') %>% 
  mutate(salary = case_when(salary == "low" ~ 1,
                            salary == "medium" ~ 2,
                            salary == "high" ~ 3)) %>% 
  #select(-sales) %>% 
  mutate(left = as.factor(left)) %>% 
  mutate(id = row_number()) %>% 
  mutate(sales = as.factor(sales)) %>% 
  na.omit %>% distinct

glimpse(hr)
table(hr$left)

train_hr <- sample_frac(hr, 0.8) 
test_hr <- anti_join(hr, train_hr, by = "id") %>%  select(-id)
train_hr <- train_hr %>%  select(-id)

table(train_hr$left)/nrow(train_hr)
table(test_hr$left)/nrow(test_hr)
table(hr$left)/nrow(hr)

# -------------------------------------
# fit dt for satisfaction

hr2 <- read_csv('./kaggle_hr_analytics.csv')

dt_satisfaction <- rpart(satisfaction_level ~ last_evaluation + number_project +
                           time_spend_company, data = hr2)
rpart.plot(dt_satisfaction)

# --------------------------------------
# fit for left JWITH satisfaction
# limit maxdepth 
# two groups of leavers: totally overworked long-stayers, and left to their own devices.
# different story, as satsifaction not part of this - its about workload.


dt_nosat <- rpart(left ~ ., data =hr2, 
                          control=rpart.control(maxdepth=3))
rpart.plot(dt_nosat, cex=0.6)

p <- ifelse(predict(dt_nosat, type="vector") > 0.5, 1, 0)
table(hr$left, p) %>% 
  confusionMatrix()

# fit for left without satisfaction
# limit maxdepth 
# two groups of leavers: totally overworked long-stayers, and left to their own devices.
# different story, as satsifaction not part of this - its about workload.


dt_nosat <- rpart(left ~ ., data = select(hr2, -satisfaction_level), 
                  control=rpart.control(maxdepth=3))
rpart.plot(dt_nosat, cex=0.6)

p <- ifelse(predict(dt_nosat, type="vector") > 0.5, 1, 0)
table(hr$left, p) %>% 
  confusionMatrix()

# --------------------------------------

# --------------------------------------
# rf by dept predicting leavers

rf_sat <- randomForest(left ~ satisfaction_level + last_evaluation, data = train_hr)
rf_sat

varImp(rf_sat)
# --------------------------------------

# rf just dept and num projects

rf_dept <- randomForest(left ~ sales + number_project, data = train_hr)
rf_dept

varImp(rf_dept)

# jsut num projects
rf_proj <- randomForest(left ~ number_project, data = train_hr)
rf_proj

d <- hr %>% 
  distinct(sales, number_project)

predict(rf_dept, d, type = "prob") %>% 
  data.frame %>%  
  cbind(d)  %>% 
  filter(X0 <0.7)

# --------------------------------------

# rf no satisfaction

rf_nosat <- randomForest(left ~ ., data = train_hr %>% select(-satisfaction_level))
rf_nosat
varImp(rf_nosat)
varImpPlot(rf_nosat)

pred1 <- predict(rf_nosat, newdata=train_hr, type="prob")[,2] %>% 
  as.numeric

pred <- predict(rf_nosat, newdata=test_hr, type="prob")[,2] %>% 
  as.numeric

train_hr_nosat_roc <- roc(train_hr$left, pred1)
test_hr_nosat_roc <- roc(test_hr$left, pred)

auc(train_hr_nosat_roc)
plot(train_hr_nosat_roc)

auc(test_hr_nosat_roc)
plot(test_hr_nosat_roc)
# --------------------------------------

# fit RF all variables
rf <- randomForest(left ~ ., data = train_hr)
rf


rf$confusion[,1:2] %>% 
  as.table %>% 
  confusionMatrix()

pred <- predict(rf, newdata=train_hr, type="prob")[,2] %>% 
  as.numeric

train_hr_roc <- roc(train_hr$left, pred)
auc(train_hr_roc)
plot(train_hr_roc)


coords(train_hr_roc, 'best', transpose = FALSE)

pred <- predict(rf, newdata=test_hr, type="prob")[,2] %>% 
  as.numeric

test_hr_roc <- roc(test_hr$left, pred)
auc(test_hr_roc)
plot(test_hr_roc)

varImpPlot(rf)

# ----------------------------------

# correlation matrix

numeric_data <- select_if(hr, is.numeric)
cor_matrix <- cor(numeric_data)

print(cor_matrix)

# Plot the correlation matrix
corrplot(cor_matrix, method = "circle")

ggpairs(numeric_data)



# ----------------------------------------------

hr %>% 
  count(sales, left) %>% 
  group_by(sales) %>% 
  mutate(p=n / sum(n)) %>% 
  ggplot(aes(x = "", y=p, fill = left)) + 
  geom_col() +
  scale_fill_manual(values=c("skyblue", "forestgreen"))+
  facet_wrap(~ sales) +
  scale_y_continuous(breaks=NULL)+
  scale_x_discrete(breaks=NULL)+
  coord_polar(theta = "y") 

# -----------------------------------------

D <- sample_n(train_hr, 300)

library(iml)
yt_pred <- Predictor$new(model = rf, data=D, y= D$left, type="prob")
yt_effect <- FeatureEffect$new(yt_pred, grid.size =100,
                               method = "pdp",
                               feature = "satisfaction_level")

yt_effect$plot() +
  #coord_cartesian(xlim = c(0,3))+
  xlab("Satisfaction")+
  ylab("Prob of leaving")

# ----------------------------------------------
# More than 250-280 is too many

D <- sample_n(train_hr, 300)

library(iml)
yt_pred <- Predictor$new(model = rf, data=D, y= D$left, type="prob")
yt_effect <- FeatureEffect$new(yt_pred, grid.size =100,
                               method = "pdp+ice",
                               feature = "average_montly_hours")

yt_effect$plot() +
  #coord_cartesian(xlim = c(0,3))+
  xlab("Average monthly hours")+
  ylab("Prob of leaving")

# ----------------------------------------------

D <- sample_n(train_hr, 300)

library(iml)
yt_pred <- Predictor$new(model = rf, data=D, y= D$left, type="prob")
yt_effect <- FeatureEffect$new(yt_pred, grid.size =100,
                               method = "pdp+ice",
                               feature = "last_evaluation")

yt_effect$plot() +
  #coord_cartesian(xlim = c(0,3))+
  xlab("Last evaluation")+
  ylab("Prob of leaving")
 
# ----------------------------------------------
# more than six is too many

D <- sample_n(train_hr, 300)

library(iml)
yt_pred <- Predictor$new(model = rf, data=D, y= D$left, type="prob")
yt_effect <- FeatureEffect$new(yt_pred, grid.size =100,
                               method = "pdp+ice",
                               feature = "number_project")

yt_effect$plot() +
  #coord_cartesian(xlim = c(0,3))+
  xlab("Number of projects")+
  ylab("Prob of leaving") 

# ----------------------------------------------
# 4-6 years most likely to leave - work on retaining these

D <- sample_n(train_hr, 300)

library(iml)
yt_pred <- Predictor$new(model = rf, data=D, y= D$left, type="prob")
yt_effect <- FeatureEffect$new(yt_pred, grid.size =100,
                               method = "pdp+ice",
                               feature = "time_spend_company")

yt_effect$plot() +
  #coord_cartesian(xlim = c(0,3))+
  xlab("Time in company")+
  ylab("Prob of leaving")

# --------------------------------------------------------

ggplot(hr, aes(x=satisfaction_level, y=average_montly_hours, color=left, alpha=0.0001)) +
  geom_point() +
  labs(title="Job Satisfaction vs. Monthly hours", x="Job Satisfaction", y="Monthly hours")

# Calculate correlation
cor(hr$satisfaction_level, hr$average_montly_hours, use="complete.obs")
# ---------------------------------------------

ggplot(hr, aes(x=satisfaction_level, y=last_evaluation, color=left, alpha=0.0001)) +
  geom_point() +
  labs(title="Job Satisfaction vs. Last evaluation", x="Job Satisfaction", y="Last evaluation")

# Calculate correlation
cor(hr$satisfaction_level, hr$last_evaluation, use="complete.obs")

# -----------------------------------------------------

ggplot(hr, aes(x=average_montly_hours, y=last_evaluation, color=left, alpha=0.00001)) +
  geom_point() +
  labs(title="Average hours vs. Last evaluation", x="Avg monthly hrs", y="Last evaluation")

# Calculate correlation
cor(hr$average_montly_hours, hr$last_evaluation, use="complete.obs")

# -----------------------------------------------------

ggplot(hr, aes(x=average_montly_hours, y=number_project, color=left, alpha=0.0001)) +
  geom_jitter() +
  labs(title="Average hours vs. Number of projects", x="Avg monthly hrs", y="Number projects")

# Calculate correlation
cor(hr$average_montly_hours, hr$number_project, use="complete.obs")

# -----------------------------------------------------

ggplot(hr, aes(x=satisfaction_level, y=last_evaluation, color=left, alpha=0.0001)) +
  geom_jitter() +
  labs(title="Satisfaction vs. Last evaluation", x="Satisfaction", y="Last evaluation")

# Calculate correlation
cor(hr$satisfaction_level, hr$last_evaluation, use="complete.obs")

# ----------------------------------------------
#logistic regression

hr <- hr %>%  mutate(sales = relevel(sales, ref="sales"))

f <- glm(left ~ sales+1, data=hr, family = "binomial") 


#relative log odds of quitting (compared to ?)
summary(f)
coef(f)
# odds of quitting - comparing to accounging
confint(f) %>%  exp

# ---------------------------------------------
#confidence intervals for odds of someone quitting by dept. If odds are 1, 
#no added risk (compared with sales)

f_confint <- confint(f) %>%  exp

as_tibble(f_confint, rownames = "var") %>%
  mutate(var=fct_reorder(var, `97.5 %`)) %>% 
  ggplot(aes(x=`2.5 %`, xend = `97.5 %`, y=var, yend=var)) +
  geom_segment() +
  geom_vline(xintercept=1)

#compared with nothing (0)

f <- glm(left ~ 0, data=hr, family = "binomial")
confint(f) %>%  exp

as_tibble(f_confint, rownames = "var") %>%
  mutate(var=fct_reorder(var, `97.5 %`)) %>% 
  ggplot(aes(x=`2.5 %`, xend = `97.5 %`, y=var, yend=var)) +
  geom_segment() +
  geom_vline(xintercept=1)

# ----------------------------------------------
d <- read_csv('./kaggle_hr_analytics.csv') %>%  sample_frac(size=0.5)

# Create a parallel coordinates plot
fig <- plot_ly(data = d, type = 'parcoords',
               line = list(color = ~left,
                           colorscale = list(c(0, '#0b718a'), c(1, '#e0b489'))),
               dimensions = list(
                 list(range = c(0,1),
                      label = 'Left', values = ~left),
                 list(range = c(0,1),
                      label = 'Job Sat', values = ~satisfaction_level),
                 list(range = c(0.36,1),
                      label = 'Last Eval', values = ~last_evaluation),
                 list(range = c(2,10),
                      label = 'Tenure', values = ~time_spend_company),
                 list(range = c(2,7),
                      label = 'Numb projs', values = ~number_project),
                 list(range = c(96,310),
                      label = 'Avg mthly hrs', values = ~average_montly_hours)
               ))

# display plot
fig

# --------------------------------------------------

kfolds <- 10
cv_folds <- sample(1:kfolds, size = nrow(hr), replace = T)

all_auc <- numeric(kfolds)
all_acc <- numeric(kfolds)
for(k in 1:kfolds) {
  print(k)
  hr_test <- hr[cv_folds == k, ]
  hr_train <- hr[cv_folds != k, ]
  
  hr_dt <- rpart(left ~ ., data = hr_train, control = rpart.control(maxdepth = 3))
  d <- tibble(pred = predict(hr_dt, newdata = hr_test)[,2],
              pred_class = predict(hr_dt, newdata = hr_test, type = 'class'),
              obs = hr_test$left)
  dt_roc_test <- roc(response = d$obs, predictor = d$pred)#roc(d, obs, pred)
  all_auc[k] <- auc(dt_roc_test)
  all_acc[k] <- sum(d$obs == d$pred_class) / nrow(hr_test)
}
mean(all_auc) # area under the curve
mean(all_acc) # accuracy

# -----------------------------------------------------

# multiple linear regression with R2 and 

hr_train_lm <- train_hr %>%  select(-sales)
hr_test_lm <- test_hr %>% select(-sales)

satisfaction_lm <- lm(satisfaction_level ~ ., 
              data = hr_train_lm)

d_train <- tibble(predicted = predict(satisfaction_lm, newdata= hr_train_lm), 
                  set = "train", observed = hr_train_lm$satisfaction_level)
d_test <- tibble(predicted = predict(satisfaction_lm, newdata = hr_test_lm), 
                 set = "test", observed = hr_test_lm$satisfaction_level)
d <- bind_rows(d_train, d_test) %>% 
  mutate(set = factor(set, levels = c('train', 'test')))

ssres_train <- sum((d_train$predicted - d_train$observed)^2)
ssres_test <- sum((d_test$predicted - d_test$observed)^2)

# Calculate the total variance in the observed data (Total Sum of Squares)
sstot_train <- sum((d_train$observed - mean(d_train$observed))^2)
sstot_test <- sum((d_test$observed - mean(d_test$observed))^2)

# Calculate R^2 (R-squared) values for both training and testing datasets
r2_train <- 100 * (1 - ssres_train / sstot_train)
r2_test <- 100 * (1 - ssres_test / sstot_test)


r2 <- tibble(
  x = 0.05,  # More towards the start of the x-axis
  y = 0.80,  # Towards the top of the y-axis, but inside the plot area
  lbl = sprintf("Perc. Variance (R2): %1.2f%%", c(r2_train, r2_test)),
  set = factor(c('train', 'test'))
)

ggplot(d) +
  stat_smooth(aes(x = observed, y = predicted), method = 'lm', color = 'grey10') +
  geom_point(aes(x = observed, y = predicted), color = 'cadetblue', alpha = 0.3) +
  facet_wrap(~ set) +
  labs(title = 'Satisfaction: Linear Regression',
       x = 'Observed satisfaction', y = 'Predicted satisfaction') +
  coord_equal() +
  #scale_x_continuous(limits = c(0, 1)) +  # Adjusted from xlim(0, 1) +
  #scale_y_continuous(limits = c(0, 1)) +  # Adjusted from ylim(0, 1) +
  geom_text(data = r2, aes(x, y, label = lbl), hjust = 0, vjust = 0, color = 'black') +
  theme_minimal()

# ---------------

# Adding residuals for visualization
d_train$residuals <- residuals(satisfaction_lm)

#training
ggplot(d_train, aes(x = predicted, y = residuals)) +
  geom_point() +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  labs(x = "Fitted Values", y = "Residuals", title = "Residuals vs. Fitted (Training Data)")



plot(test_hr_roc)
auc(test_hr_roc)

plot(test_hr_nosat_roc)
auc(test_hr_nosat_roc)

yt_effect <- FeatureEffect$new(..., feature = "average_montly_hours")
yt_effect$plot()

hr %>% 
  count(sales, left) %>% 
  group_by(sales) %>% 
  mutate(p = n / sum(n)) %>% 
  ggplot(aes(x = "", y = p, fill = left)) + 
  geom_col() +
  scale_fill_manual(values = c("skyblue", "forestgreen")) +
  facet_wrap(~ sales) +
  scale_y_continuous(breaks = NULL) +
  scale_x_discrete(breaks = NULL) +
  coord_polar(theta = "y") +
  labs(title = "Attrition Proportion by Department")


# Identification of high-risk high-performance employees
# Predicted probability of leaving
pred <- predict(rf, newdata = test_hr, type = "prob")[,2]
# Combine with test data
d_plot <- test_hr %>%
  mutate(pred_prob = pred)
# Plot
ggplot(d_plot, aes(x = pred_prob, y = last_evaluation)) +
  geom_point(alpha = 0.3, color = "steelblue") +
  geom_vline(xintercept = 0.6, linetype = "dashed", color = "red") +
  geom_hline(yintercept = 0.8, linetype = "dashed", color = "red") +
  labs(
    title = "Identification of High-Risk High-Performance Employees",
    x = "Predicted Probability of Leaving",
    y = "Last Evaluation Score"
  ) +
  theme_minimal()
