class groupDefinition {
    #id;
    #level;
    #parentId;
    #name;
    #budget;
    #ownerEmail;
    #departmentEmail;

    constructor(id = null, level = null, parentId = null, name = null, budget = null, ownerEmail = null, departmentEmail = null) {
        this.id = id,
        this.level = level,
        this.parentId = parentId,
        this.name = name,
        this.budget = budget,
        this.ownerEmail = ownerEmail,
        this.departmentEmail = departmentEmail
    }

    get id() {
        return this.id
    }

    set id() {
        throw "Group IDs are set by the server"
    }

    get level() {
        return this.level
    }

    set level(groupLevel) {
        if (groupLevel > 0 && groupLevel < 4 && !isNaN(groupLevel)) {
            this.level = groupLevel
        } else {
            throw "Group Levels must be whole numbers between 1 & 3"
        }
    }

    get parentId() {
        return this.parentId
    }

    set parentId(parentGroupId) {
            if (this.level != 1) {
                this.parentId = parentGroupId
            } else {
                throw "Level 1 Groups cannot have parents"
            }
    }

    get name() {
        return this.name
    }

    set name(groupName) {
        this.name = groupName
    }

    get budget() {
        return this.budget
    }

    set budget(monthlySpend) {
        this.budget = monthlySpend
    }

    get ownerEmail() {
        return this.ownerEmail
    }

    set ownerEmail(emailAddress) {
        this.ownerEmail = emailAddress
    }

    get departmentEmail() {
        return this.departmentEmail
    }

    set departmentEmail(emailAddress) {
        this.departmentEmail = emailAddress
    }

    getSQLParameters() {
        let params = []
        let param = {}

        param.name = "id"
        param.type = "UNIQUEIDENTIFIER"
        param.value = this.id
    
        params.push(param)
    
        param.name = "level"
        param.type = "INT"
        param.value = this.level

        params.push(param)

        param.name = "parentId"
        param.type = "UNIQUEIDENTIFIER"
        param.value = this.parentId

        params.push(param)

        param.name = "name"
        param.type = "VARCHAR(255)"
        param.value = this.name

        params.push(param)

        param.name = "budget"
        param.type = "INT"
        param.value = this.budget

        params.push(param)

        param.name = "ownerEmail"
        param.type = "VARCHAR(255)"
        param.value = this.ownerEmail

        params.push(param)

        param.name = "departmentEmail"
        param.type = "VARCHAR(255)"
        param.value = this.departmentEmail

        params.push(param)

        return params
    }

    loadGroupDefinition(existingGroupDefinition) {
        this.id = existingGroupDefinition.id
        this.level = existingGroupDefinition.level
        this.parentId = existingGroupDefinition.parentId
        this.name = existingGroupDefinition.name
        this.budget = existingGroupDefinition.budget
        this.ownerEmail = existingGroupDefinition.ownerEmail
        this.departmentEmail = existingGroupDefinition.departmentEmail
    }
}