---
title: "Separation of Concerns through Layered Design"
date: 2022-04-13T00:00:00+07:00
draft: false
---

## Introduction

One of the well-known practices in software engineering when building information rich applications is layering it into different layers based on its concerns. I have seen many folks recommending this practice in many discussions, i.e blogpost, twitter discussion, linkedin post, etc. In this post, I'll try to rephrase it with more details.

Before going deep into detail of this principles, let's define what's problem we're going to solve with this principle. Here's some problems that we're trying to solve with this principle in mind.

Testing is becoming hard & costly when the components are tighly coupled, the reason that testing is becoming costly & hard because when we want to test specific logic, the test also need to againts all layers or components.

Developer need to pull information from multiple aspects to understand and enhance the systems,

To solve or to reduce the problems above, we can adopt Separation of Concerns principle. Here are some benefits of separation of concerns.

Reducing cognitive load needed in understanding the systems

Enable us to test the core (or specific) part with low effort

## Reducing cognitive load

Before going into it, let's familiarize with what is "Cognitive Load". "Cognitive Load" relates to the amount of information that working memory can hold at a time. In this context, it can relates to how much variant of information we need to know in order to complete the task. The risk of a higher cognitive load is we can easily create bugs because we may miss some required information in order to complete the task.

For example, when developing feature where its software components are not separated nicely, we tend to look at all layers. We have to pull all information from all layers and combine them in order to complete the feature. Beside of it is error-prone, it also has maintainance cost because we have to put all informations everytime there's task related to it.

## Enable unit testing

As we defined above, another benefit of this principles is enabling us to achieve lower effort of testing. For example, when we want to test the business logic of the software systems, we can do it without dealing with how we store the data in the database.

## High level design

![image alt text](/separation-of-concerns/basic-landscape.png)

In the diagram above, we split the software systems into 3 layers, presentation layer, business logic or domain layer, and persistence layer.

Presentation layer, is the layer which handles request from client, process it using other layer, and send the response back to the client.

Business logic or domain layer, is the layer which handles the core of the domain logic

Persistence layer, is the layer which responsible to storing & retrieving data from data storage.

In some cases, where the domain is a bit complex we also can split the business logic into 2 distinct components, service and domain objects where we can place the business logic in service or domain objects.

- service
- domain objects

Here's the diagram for implementing the service & domain objects.

![image alt text](/separation-of-concerns/service-domain-objects-landscape.png)

## Low-level implementation

To demonstrate the low-level implemenation of this principle, I'll try write some code snippet. Let's take the case of food delivery order submission. The requirement we need to cater here is calculating order total amount based on its items.

**Pesistence Layer**

```go
type OrderRepository interface {
    StoreOrder(order *Order) (*Order, error)
    FindByID(orderID string) (*Order, error)
}
```

As the persistence only responsible to storing & retrieving data in data storage, the function signature also only express those responsibilities.

**Business logic layer (domain objects)**

```go
type Order struct {
	ID       int         `json:"id"`
	Subtotal int         `json:"subTotal"`
	Total    int         `json:"total"`
	Items    []OrderItem `json:"items"`
}

type OrderItem struct {
	ID        int `json:"id"`
	ProductID int `json:"productId"`
	Price     int `json:"price"`
	Qty       int `json:"qty"`
}

func (o *Order) AddItem(productID int, price int) error {
	m := make(map[int]OrderItem, 0)
	for _, item := range o.Items {
		m[item.ProductID] = item
	}
    // Update qty if the productID have been registered
	exist, item := m[productID]
	if exist {
		item.Qty += 1
		m[productID] = item
	}
    // Calculate subtotal based on product price & quantity
	o.Items = make([]OrderItem, 0)
	subTotal := 0
	for _, item := range o.Items {
		o.Items = append(o.Items, item)
		subTotal += (item.Price * item.Qty)
	}
	o.Total = subTotal
	o.SubTotal = subTotal
	return nil
}
```

**Business logic layer (service)**

```go
func (o OrderService) AddItem(orderID int, input AddItemInput) (*Order, error) {
    order, err := o.repository.FindByID(order.ID)
    if err != nil {
        return nil, err
    }
    price := 90000 // Dummy price
    err = order.AddItem(input.ProductID, price)
    if err != nil {
        return nil, err
    }
    err := o.repository.StoreOrder(order)
    if err != nil {
        return nil, err
    }
    return order, nil 
}
```

As you can see above, the logic of how to add new product into Order is fully implemented in domain objects, not in service layer. In service layer only handle the integration with other layers (persistence layer) and the domain logic.

## Challenges

There are some challenges or things to be considered in implementing this principle in real world application as this will be anti-pattern if we try to implement this blindly without considering the context of our case.

How to adopt this principle in more complex system where it involves multiple domain models?

How to implement this principle when the system need to handle logic that's not really related to domain itself?

To discuss the challenges above in more detail, I'll try elaborate it one by one.

**Challenge #1**

As the application grows, the application becomes more complex, it will manage multiple domain models most of the cases. In this state, it's better to revisit our design and implementation by spliting the design logically into separated modules. The Separation of Concern principles can be implemented in each modules. So each module manage its own persistence & business logic layers, or even the persistence layer. Here is the diagram of this design for mitigating this challenge.

![image alt text](/separation-of-concerns/multiple-namespace.png)

**Challenge #2**

For this challenge, we can place the logics outside of our domain logic layers if that's not really related to our business domains or we partition the service layer into distinct components. Here are some examples of logics that may not be considered in our business domains.

A logic to compose notification content

A logic to handle specific use-case in presentation layer.

etc

But if we can have less components for the service layers, do it.

## Conclusion

In this articles we have addressed some challenge that may be happened the implementation of this principles and also have demonstrated in how to place the domain logics in the domain objects and did its integration in the service layer.

## References

- [Cognitive Load] https://www.mindtools.com/pages/article/cognitive-load-theory.htm
- [PresentationDomainDataLayering] https://martinfowler.com/bliki/PresentationDomainDataLayering.html
